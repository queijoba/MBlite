create table if not exists public.mblite_visit_sessions(
 visit_day date not null default ((now() at time zone 'America/Bahia')::date),
 session_id uuid not null,
 primary key(visit_day,session_id)
);
alter table public.mblite_visit_sessions enable row level security;
revoke all on public.mblite_visit_sessions from public,anon,authenticated;
grant insert(session_id) on public.mblite_visit_sessions to anon,authenticated;
create policy mblite_visit_insert on public.mblite_visit_sessions for insert to anon,authenticated with check (visit_day=(now() at time zone 'America/Bahia')::date);
create or replace function mblite_access_private.dashboard_stats() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); today date:=(now() at time zone 'America/Bahia')::date;
begin
 if u is null or not exists(select 1 from mblite_access_private.admins a join auth.users au on au.id=a.user_id where a.user_id=u and au.email_confirmed_at is not null and not au.is_anonymous) then return jsonb_build_object('ok',false,'error','Acesso administrativo negado.'); end if;
 return jsonb_build_object('ok',true,'today',today,
 'visits_total',(select count(*) from public.mblite_visit_sessions),
 'visits_today',(select count(*) from public.mblite_visit_sessions where visit_day=today),
 'visits_week',(select count(*) from public.mblite_visit_sessions where visit_day>=today-6),
 'users_total',(select count(*) from auth.users where not is_anonymous),
 'users_confirmed',(select count(*) from auth.users where not is_anonymous and email_confirmed_at is not null),
 'keys_total',(select count(*) from mblite_access_private.keys),
 'keys_used',(select count(*) from mblite_access_private.keys where redeemed_at is not null),
 'keys_available',(select count(*) from mblite_access_private.keys where redeemed_at is null and revoked_at is null),
 'accounts_unlocked',(select count(distinct user_id) from mblite_access_private.entitlements),
 'grants',(select count(*) from mblite_access_private.entitlements),
 'pending_requests',(select count(*) from mblite_access_private.key_requests where status in ('novo','em análise')),
 'visits_daily',(select jsonb_agg(jsonb_build_object('day',d,'visits',n) order by d) from (select today-i as d,(select count(*) from public.mblite_visit_sessions where visit_day=today-i) as n from generate_series(0,6) i)x),
 'systems',(select coalesce(jsonb_agg(jsonb_build_object('system',system,'accounts',accounts,'grants',grants) order by system),'[]'::jsonb) from (select system,count(distinct user_id) accounts,count(*) grants from (select user_id,case when scope like 'op-%' then 'Ordem Paranormal' when scope like 't20-%' then 'Tormenta20' when scope like '3det-%' then '3D&T' when scope like 'pf2e-%' then 'Pathfinder 2e' when scope like 'dnd-%' then 'D&D' else 'Outros' end system from mblite_access_private.entitlements)e group by system)s));
end $$;
revoke all on function mblite_access_private.dashboard_stats() from public,anon,authenticated;
grant execute on function mblite_access_private.dashboard_stats() to authenticated;
create or replace function public.mblite_dashboard_stats() returns jsonb language sql security invoker set search_path='' as $$ select mblite_access_private.dashboard_stats() $$;
revoke all on function public.mblite_dashboard_stats() from public,anon,authenticated;
grant execute on function public.mblite_dashboard_stats() to authenticated;
notify pgrst,'reload schema';