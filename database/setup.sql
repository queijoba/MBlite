-- Execute somente no projeto MBLite separado. Não executar no PJ Lite.
begin;
create table public.mblite_books (id text primary key check (length(id) between 1 and 80));
insert into public.mblite_books(id) values ('got-basic'),('got-night'),('got-posses'),('got-porto'),('got-ficha'),('got-ficha-alt');
create table public.mblite_reader_state (
 user_id uuid not null references auth.users(id) on delete cascade,
 book_id text not null references public.mblite_books(id) on delete cascade,
 favorite boolean not null default false, wishlist boolean not null default false,
 last_seen timestamptz, primary key(user_id,book_id)
);
create table public.mblite_comments (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 book_id text not null references public.mblite_books(id) on delete cascade,
 author text not null check (char_length(btrim(author)) between 1 and 40),
 body text not null check (char_length(btrim(body)) between 1 and 1000),
 spoiler boolean not null default false, parent_id uuid,
 created_at timestamptz not null default now(),
 unique(id,book_id), foreign key(parent_id,book_id) references public.mblite_comments(id,book_id) on delete cascade
);
create index mblite_comments_book_created on public.mblite_comments(book_id,created_at desc);
create index mblite_comments_parent on public.mblite_comments(parent_id);
create table public.mblite_comment_likes (
 comment_id uuid not null references public.mblite_comments(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 primary key(comment_id,user_id)
);
alter table public.mblite_books enable row level security;
alter table public.mblite_reader_state enable row level security;
alter table public.mblite_comments enable row level security;
alter table public.mblite_comment_likes enable row level security;
revoke all on public.mblite_books,public.mblite_reader_state,public.mblite_comments,public.mblite_comment_likes from anon,authenticated;
grant select on public.mblite_books to authenticated;
grant select,insert,update,delete on public.mblite_reader_state to authenticated;
grant select,delete on public.mblite_comments to authenticated;
grant insert(user_id,book_id,author,body,spoiler,parent_id) on public.mblite_comments to authenticated;
grant select,insert,delete on public.mblite_comment_likes to authenticated;
create policy mblite_book_read on public.mblite_books for select to authenticated using ((select auth.uid()) is not null);
create policy mblite_state_select on public.mblite_reader_state for select to authenticated using ((select auth.uid()) = user_id);
create policy mblite_state_insert on public.mblite_reader_state for insert to authenticated with check ((select auth.uid()) = user_id);
create policy mblite_state_update on public.mblite_reader_state for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy mblite_state_delete on public.mblite_reader_state for delete to authenticated using ((select auth.uid()) = user_id);
create policy mblite_comments_read on public.mblite_comments for select to authenticated using ((select auth.uid()) is not null);
create policy mblite_comments_insert on public.mblite_comments for insert to authenticated with check ((select auth.uid()) = user_id and author = left(coalesce(nullif((select auth.jwt())->'user_metadata'->>'nickname',''),'Leitor'),40));
create policy mblite_comments_delete on public.mblite_comments for delete to authenticated using ((select auth.uid()) = user_id);
create policy mblite_likes_read on public.mblite_comment_likes for select to authenticated using ((select auth.uid()) is not null);
create policy mblite_likes_insert on public.mblite_comment_likes for insert to authenticated with check ((select auth.uid()) = user_id);
create policy mblite_likes_delete on public.mblite_comment_likes for delete to authenticated using ((select auth.uid()) = user_id);
commit;
