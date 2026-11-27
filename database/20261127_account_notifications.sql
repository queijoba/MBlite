begin;
alter table public.mblite_reader_state add column favorite_since timestamptz;
update public.mblite_reader_state set favorite_since=now() where favorite;
create function public.mblite_favorite_timestamp() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if not new.favorite then new.favorite_since=null;
 elsif tg_op='INSERT' then new.favorite_since=now();
 elsif not old.favorite then new.favorite_since=now();
 else new.favorite_since=old.favorite_since; end if;
 return new;
end $$;
revoke execute on function public.mblite_favorite_timestamp() from public,anon,authenticated;
create trigger mblite_favorite_timestamp before insert or update on public.mblite_reader_state for each row execute function public.mblite_favorite_timestamp();
create table public.mblite_book_updates(id uuid primary key default gen_random_uuid(),book_id text not null references public.mblite_books(id) on delete cascade,description text not null check(char_length(description) between 1 and 300),created_at timestamptz not null default now());
create index mblite_book_updates_idx on public.mblite_book_updates(book_id,created_at desc);
alter table public.mblite_book_updates enable row level security;
revoke all on public.mblite_book_updates from anon,authenticated;
grant select on public.mblite_book_updates to authenticated;
create policy mblite_book_updates_read on public.mblite_book_updates for select to authenticated using ((select auth.uid()) is not null);
create table public.mblite_notification_reads(user_id uuid primary key references auth.users(id) on delete cascade,last_read_at timestamptz not null default now());
alter table public.mblite_notification_reads enable row level security;
revoke all on public.mblite_notification_reads from anon,authenticated;
grant select,insert,update on public.mblite_notification_reads to authenticated;
create policy mblite_notification_select on public.mblite_notification_reads for select to authenticated using ((select auth.uid())=user_id);
create policy mblite_notification_insert on public.mblite_notification_reads for insert to authenticated with check ((select auth.uid())=user_id);
create policy mblite_notification_update on public.mblite_notification_reads for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create function public.mblite_notification_feed() returns table(event_id uuid,book_id text,kind text,message text,created_at timestamptz,unread boolean) language sql stable security invoker set search_path='' as $$
with me as (select auth.uid() as uid),
favorites as (select s.book_id,s.favorite_since from public.mblite_reader_state s,me where s.user_id=me.uid and s.favorite),
events as (
 select c.id,c.book_id,case when p.user_id=me.uid then 'reply' else 'comment' end as kind,
 case when p.user_id=me.uid then 'Responderam ao seu comentário' else 'Novo comentário em uma obra favorita' end as message,c.created_at
 from public.mblite_comments c cross join me
 left join public.mblite_comments p on p.id=c.parent_id
 left join favorites f on f.book_id=c.book_id
 where me.uid is not null and c.user_id<>me.uid and (p.user_id=me.uid or c.created_at>=f.favorite_since)
 union all
 select u.id,u.book_id,'update',u.description,u.created_at from public.mblite_book_updates u join favorites f on f.book_id=u.book_id and u.created_at>=f.favorite_since
)
select e.id,e.book_id,e.kind,e.message,e.created_at,e.created_at>coalesce(r.last_read_at,'-infinity'::timestamptz)
from events e cross join me left join public.mblite_notification_reads r on r.user_id=me.uid
where e.created_at>=now()-interval '30 days' order by e.created_at desc,e.id limit 100;
$$;
revoke execute on function public.mblite_notification_feed() from public,anon;
grant execute on function public.mblite_notification_feed() to authenticated;
create function public.mblite_mark_notifications_read() returns void language sql security invoker set search_path='' as $$
insert into public.mblite_notification_reads(user_id,last_read_at) values(auth.uid(),now()) on conflict(user_id) do update set last_read_at=excluded.last_read_at;
$$;
revoke execute on function public.mblite_mark_notifications_read() from public,anon;
grant execute on function public.mblite_mark_notifications_read() to authenticated;
commit;