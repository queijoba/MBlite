-- MBLite Cloud only. Seed verified administrator UUID privately after migration; no user identity in public repository.

create schema mblite_access_private;
revoke all on schema mblite_access_private from public,anon,authenticated;
create table mblite_access_private.admins(user_id uuid primary key references auth.users(id) on delete cascade);
create table mblite_access_private.keys(id uuid primary key default gen_random_uuid(),scope text not null,code_hash bytea not null unique,code_hint text not null,created_at timestamptz not null default now(),created_by uuid references auth.users(id) on delete set null,redeemed_by uuid references auth.users(id) on delete set null,redeemed_at timestamptz,revoked_at timestamptz);
create table mblite_access_private.entitlements(user_id uuid not null references auth.users(id) on delete cascade,scope text not null,granted_at timestamptz not null default now(),primary key(user_id,scope));
create table mblite_access_private.attempts(user_id uuid primary key references auth.users(id) on delete cascade,window_at timestamptz not null default now(),attempts int not null default 0);
create table mblite_access_private.tickets(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,category text not null check(category in ('materiais','tester','suporte','doacao')),platform text not null check(platform in ('Discord','WhatsApp','Telegram','Reddit')),contact text not null check(char_length(contact) between 1 and 200),message text not null check(char_length(message)<=1500),status text not null default 'novo' check(status in ('novo','em atendimento','encerrado')),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
alter table mblite_access_private.admins enable row level security;
alter table mblite_access_private.keys enable row level security;
alter table mblite_access_private.entitlements enable row level security;
alter table mblite_access_private.attempts enable row level security;
alter table mblite_access_private.tickets enable row level security;
revoke all on all tables in schema mblite_access_private from public,anon,authenticated;
create function mblite_access_private.dispatch(p_action text,p_data jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); admin boolean; sc text; c text; k mblite_access_private.keys%rowtype; n int; t uuid; cat text; plat text; con text; msg text; st text;
begin
 if u is null or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null and not is_anonymous) then return jsonb_build_object('ok',false,'error','Entre com uma conta confirmada.'); end if;
 select exists(select 1 from mblite_access_private.admins where user_id=u) into admin;
 if p_action='state' then
 return jsonb_build_object('ok',true,'admin',admin,'scopes',coalesce((select jsonb_agg(scope order by scope) from mblite_access_private.entitlements where user_id=u),'[]'::jsonb),'new_tickets',case when admin then (select count(*) from mblite_access_private.tickets where status='novo') else 0 end);
 elsif p_action='access' then
 sc:=p_data->>'book';
 return jsonb_build_object('ok',true,'allowed',sc is not null and sc like 'op-%' and exists(select 1 from public.mblite_books where id=sc) and (admin or exists(select 1 from mblite_access_private.entitlements where user_id=u and scope in ('op-all',sc))));
 elsif p_action='redeem' then
 insert into mblite_access_private.attempts(user_id,attempts) values(u,1) on conflict(user_id) do update set attempts=case when mblite_access_private.attempts.window_at < now()-interval '15 minutes' then 1 else mblite_access_private.attempts.attempts+1 end,window_at=case when mblite_access_private.attempts.window_at < now()-interval '15 minutes' then now() else mblite_access_private.attempts.window_at end returning attempts into n;
 if n>10 then return jsonb_build_object('ok',false,'error','Muitas tentativas. Aguarde 15 minutos.'); end if;
 c:=upper(btrim(coalesce(p_data->>'code','')));
 if c !~ '^MB-[0-9A-F]{32}$' then return jsonb_build_object('ok',false,'error','Chave inválida ou já utilizada.'); end if;
 select * into k from mblite_access_private.keys where code_hash=sha256(convert_to(c,'UTF8')) for update;
 if not found or k.revoked_at is not null or k.redeemed_at is not null then return jsonb_build_object('ok',false,'error','Chave inválida ou já utilizada.'); end if;
 if exists(select 1 from mblite_access_private.entitlements where user_id=u and scope in ('op-all',k.scope)) then return jsonb_build_object('ok',false,'error','Sua conta já possui este acesso. A chave não foi consumida.'); end if;
 insert into mblite_access_private.entitlements(user_id,scope) values(u,k.scope) on conflict do nothing;
 get diagnostics n=row_count;
 if n=0 then return jsonb_build_object('ok',false,'error','Sua conta já possui este acesso.'); end if;
 update mblite_access_private.keys set redeemed_by=u,redeemed_at=now() where id=k.id;
 return jsonb_build_object('ok',true,'scope',k.scope);
 elsif p_action='ticket_create' then
 cat:=p_data->>'category'; plat:=p_data->>'platform'; con:=btrim(coalesce(p_data->>'contact','')); msg:=btrim(coalesce(p_data->>'message',''));
 if cat is null or cat not in ('materiais','tester','suporte','doacao') or plat is null or plat not in ('Discord','WhatsApp','Telegram','Reddit') or length(con) not between 1 and 200 or length(msg)>1500 then return jsonb_build_object('ok',false,'error','Confira os campos do chamado.'); end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text, 19));
 if (select count(*) from mblite_access_private.tickets where user_id=u and created_at>now()-interval '1 day')>=5 then return jsonb_build_object('ok',false,'error','Limite de cinco chamados por dia.'); end if;
 insert into mblite_access_private.tickets(user_id,category,platform,contact,message) values(u,cat,plat,con,msg) returning id into t;
 return jsonb_build_object('ok',true,'id',t);
 elsif p_action='my_tickets' then
 return jsonb_build_object('ok',true,'tickets',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select id,category,platform,contact,message,status,created_at from mblite_access_private.tickets where user_id=u order by created_at desc limit 100)x),'[]'::jsonb));
 end if;
 if not admin then return jsonb_build_object('ok',false,'error','Acesso administrativo negado.'); end if;
 if p_action='create_key' then
 sc:=p_data->>'scope';
 if sc is null or (sc<>'op-all' and (sc not like 'op-%' or not exists(select 1 from public.mblite_books where id=sc))) then return jsonb_build_object('ok',false,'error','Escopo inválido.'); end if;
 c:='MB-'||upper(replace(gen_random_uuid()::text,'-',''));
 insert into mblite_access_private.keys(scope,code_hash,code_hint,created_by) values(sc,sha256(convert_to(c,'UTF8')),right(c,6),u) returning id into t;
 return jsonb_build_object('ok',true,'code',c,'id',t);
 elsif p_action='admin_list' then
 return jsonb_build_object('ok',true,'keys',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select k.id,k.scope,k.code_hint,k.created_at,k.redeemed_at,k.revoked_at,au.email as redeemed_email from mblite_access_private.keys k left join auth.users au on au.id=k.redeemed_by order by k.created_at desc limit 200)x),'[]'::jsonb),'tickets',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select t.id,t.category,t.platform,t.contact,t.message,t.status,t.created_at,au.email as account_email from mblite_access_private.tickets t left join auth.users au on au.id=t.user_id order by (t.status='novo') desc,t.created_at desc limit 200)x),'[]'::jsonb),'counts',jsonb_build_object('active',(select count(*) from mblite_access_private.keys where redeemed_at is null and revoked_at is null),'used',(select count(*) from mblite_access_private.keys where redeemed_at is not null),'revoked',(select count(*) from mblite_access_private.keys where revoked_at is not null),'accounts',(select count(distinct user_id) from mblite_access_private.entitlements),'new_tickets',(select count(*) from mblite_access_private.tickets where status='novo')));
 elsif p_action='revoke_key' then
 update mblite_access_private.keys set revoked_at=now() where id::text=p_data->>'id' and redeemed_at is null and revoked_at is null; get diagnostics n=row_count;
 return jsonb_build_object('ok',n=1,'error',case when n=0 then 'Chave não está ativa.' end);
 elsif p_action='ticket_status' then
 st:=p_data->>'status'; if st is null or st not in ('novo','em atendimento','encerrado') then return jsonb_build_object('ok',false,'error','Status inválido.'); end if;
 update mblite_access_private.tickets set status=st,updated_at=now() where id::text=p_data->>'id'; get diagnostics n=row_count;
 return jsonb_build_object('ok',n=1,'error',case when n=0 then 'Chamado não encontrado.' end);
 end if;
 return jsonb_build_object('ok',false,'error','Operação inválida.');
end $$;
revoke all on function mblite_access_private.dispatch(text,jsonb) from public,anon,authenticated;
grant usage on schema mblite_access_private to authenticated;
grant execute on function mblite_access_private.dispatch(text,jsonb) to authenticated;
create function public.mblite_key_action(p_action text,p_data jsonb default '{}'::jsonb) returns jsonb language sql security invoker set search_path='' as $$ select mblite_access_private.dispatch(p_action,p_data) $$;
revoke all on function public.mblite_key_action(text,jsonb) from public,anon,authenticated;
grant execute on function public.mblite_key_action(text,jsonb) to authenticated;
notify pgrst,'reload schema';
