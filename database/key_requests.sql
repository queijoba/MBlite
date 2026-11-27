
alter table mblite_access_private.keys add column assigned_to uuid references auth.users(id) on delete cascade;
create table mblite_access_private.key_requests(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 book_id text not null references public.mblite_books(id), media text not null check(media in ('fisico','pdf')),
 method text not null check(method in ('conhecido','sku','foto','compra','outro')),
 justification text not null check(char_length(justification) between 10 and 1500),
 proof text check(proof is null or (length(proof)<=480000 and proof ~ '^[A-Za-z0-9+/]+={0,2}$')),
 status text not null default 'novo' check(status in ('novo','em análise','aprovado','recusado')),
 response text, key_id uuid references mblite_access_private.keys(id) on delete set null, issued_code text,
 created_at timestamptz not null default now(), reviewed_at timestamptz, read_at timestamptz
);
alter table mblite_access_private.key_requests enable row level security;
revoke all on mblite_access_private.key_requests from public,anon,authenticated;
create index on mblite_access_private.key_requests(user_id,created_at desc);
create index on mblite_access_private.key_requests(status,created_at desc);
create or replace function mblite_access_private.request_action(p_action text,p_data jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); adm boolean; q mblite_access_private.key_requests%rowtype; bid text; med text; met text; why text; pic text; ans text; decision text; code text; kid uuid; rid uuid;
begin
 if u is null or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null and not is_anonymous) then return jsonb_build_object('ok',false,'error','Entre com uma conta confirmada.'); end if;
 select exists(select 1 from mblite_access_private.admins where user_id=u) into adm;
 if p_action='create' then
 bid:=p_data->>'book'; med:=p_data->>'media'; met:=p_data->>'method'; why:=btrim(coalesce(p_data->>'justification','')); pic:=nullif(p_data->>'proof','');
 if bid is null or mblite_access_private.scope_for(bid) is null or not exists(select 1 from public.mblite_books where id=bid) or med is null or med not in ('fisico','pdf') or met is null or met not in ('conhecido','sku','foto','compra','outro') or length(why) not between 10 and 1500 then return jsonb_build_object('ok',false,'error','Confira o livro, a mídia e a justificativa.'); end if;
 if pic is not null then
 if length(pic)>480000 or pic !~ '^[A-Za-z0-9+/]+={0,2}$' then return jsonb_build_object('ok',false,'error','Imagem inválida ou grande demais.'); end if;
 begin if substring(decode(pic,'base64') from 1 for 3)<>decode('ffd8ff','hex') then return jsonb_build_object('ok',false,'error','Envie uma imagem JPEG.'); end if; exception when others then return jsonb_build_object('ok',false,'error','Imagem inválida.'); end;
 end if;
 if coalesce((p_data->>'consent')::boolean,false) is not true then return jsonb_build_object('ok',false,'error','Confirme a declaração de aquisição.'); end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,31));
 if exists(select 1 from mblite_access_private.entitlements where user_id=u and scope in (bid,mblite_access_private.scope_for(bid))) then return jsonb_build_object('ok',false,'error','Você já tem esse acesso.'); end if;
 if exists(select 1 from mblite_access_private.key_requests kr left join mblite_access_private.keys kk on kk.id=kr.key_id where kr.user_id=u and kr.book_id=bid and (kr.status in ('novo','em análise') or (kr.status='aprovado' and kk.revoked_at is null and kk.redeemed_at is null))) then return jsonb_build_object('ok',false,'error','Já existe uma solicitação aberta para este livro.'); end if;
 if (select count(*) from mblite_access_private.key_requests where user_id=u and created_at>now()-interval '1 day')>=3 then return jsonb_build_object('ok',false,'error','Limite de três solicitações por dia.'); end if;
 insert into mblite_access_private.key_requests(user_id,book_id,media,method,justification,proof) values(u,bid,med,met,why,pic) returning id into rid;
 return jsonb_build_object('ok',true,'id',rid);
 elsif p_action='mine' then
 return jsonb_build_object('ok',true,'requests',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select kr.id,kr.book_id,kr.media,kr.method,kr.justification,kr.status,kr.response,kr.created_at,kr.reviewed_at,kr.read_at,(kr.proof is not null) as has_proof,case when kk.redeemed_at is null and kk.revoked_at is null then kr.issued_code end as code,kk.redeemed_at,kk.revoked_at from mblite_access_private.key_requests kr left join mblite_access_private.keys kk on kk.id=kr.key_id where kr.user_id=u order by kr.created_at desc limit 100)x),'[]'::jsonb));
 elsif p_action='read' then
 update mblite_access_private.key_requests set read_at=now() where user_id=u and reviewed_at is not null;
 return jsonb_build_object('ok',true);
 end if;
 if not adm then return jsonb_build_object('ok',false,'error','Acesso administrativo negado.'); end if;
 if p_action='list' then
 return jsonb_build_object('ok',true,'requests',coalesce((select jsonb_agg(to_jsonb(x) order by (x.status='novo') desc,x.created_at desc) from (select kr.id,kr.book_id,kr.media,kr.method,kr.justification,kr.status,kr.response,kr.created_at,kr.reviewed_at,(kr.proof is not null) as has_proof,au.email as account_email from mblite_access_private.key_requests kr join auth.users au on au.id=kr.user_id order by (kr.status='novo') desc,kr.created_at desc limit 200)x),'[]'::jsonb));
 elsif p_action='proof' then
 select * into q from mblite_access_private.key_requests where id::text=p_data->>'id';
 if not found then return jsonb_build_object('ok',false,'error','Chamado não encontrado.'); end if;
 return jsonb_build_object('ok',true,'proof',q.proof);
 elsif p_action='review' then
 decision:=p_data->>'decision'; ans:=btrim(coalesce(p_data->>'response',''));
 if decision is null or decision not in ('em análise','aprovado','recusado') or length(ans) not between 3 and 1500 then return jsonb_build_object('ok',false,'error','Escreva uma resposta ao leitor.'); end if;
 select * into q from mblite_access_private.key_requests where id::text=p_data->>'id' for update;
 if not found or q.status not in ('novo','em análise') then return jsonb_build_object('ok',false,'error','Chamado já finalizado ou não encontrado.'); end if;
 if decision='aprovado' then
 if coalesce((p_data->>'authorized')::boolean,false) is not true then return jsonb_build_object('ok',false,'error','Confirme o direito de acesso digital.'); end if;
 if exists(select 1 from mblite_access_private.entitlements where user_id=q.user_id and scope in (q.book_id,mblite_access_private.scope_for(q.book_id))) then return jsonb_build_object('ok',false,'error','Leitor já possui este acesso.'); end if;
 code:='MB-'||upper(replace(gen_random_uuid()::text,'-',''));
 insert into mblite_access_private.keys(scope,code_hash,code_hint,created_by,assigned_to) values(q.book_id,sha256(convert_to(code,'UTF8')),right(code,6),u,q.user_id) returning id into kid;
 end if;
 update mblite_access_private.key_requests set status=decision,response=ans,reviewed_at=now(),read_at=null,key_id=kid,issued_code=code,proof=case when decision in ('aprovado','recusado') then null else proof end where id=q.id;
 return jsonb_build_object('ok',true);
 end if;
 return jsonb_build_object('ok',false,'error','Operação inválida.');
end $$;
revoke all on function mblite_access_private.request_action(text,jsonb) from public,anon,authenticated;
grant execute on function mblite_access_private.request_action(text,jsonb) to authenticated;
create function public.mblite_request_action(p_action text,p_data jsonb default '{}'::jsonb) returns jsonb language sql security invoker set search_path='' as $$ select mblite_access_private.request_action(p_action,p_data) $$;
revoke all on function public.mblite_request_action(text,jsonb) from public,anon,authenticated;
grant execute on function public.mblite_request_action(text,jsonb) to authenticated;
create or replace function mblite_access_private.dispatch(p_action text,p_data jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); admin boolean; sc text; c text; k mblite_access_private.keys%rowtype; n int; t uuid; cat text; plat text; con text; msg text; st text;
begin
 if u is null or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null and not is_anonymous) then return jsonb_build_object('ok',false,'error','Entre com uma conta confirmada.'); end if;
 select exists(select 1 from mblite_access_private.admins where user_id=u) into admin;
 if p_action='state' then
 return jsonb_build_object('ok',true,'admin',admin,'scopes',coalesce((select jsonb_agg(scope order by scope) from mblite_access_private.entitlements where user_id=u),'[]'::jsonb),'new_tickets',case when admin then (select count(*) from mblite_access_private.tickets where status='novo') else 0 end,'new_requests',case when admin then (select count(*) from mblite_access_private.key_requests where status='novo') else 0 end,'request_replies',(select count(*) from mblite_access_private.key_requests where user_id=u and reviewed_at is not null and read_at is null));
 elsif p_action='access' then
 sc:=p_data->>'book';
 return jsonb_build_object('ok',true,'allowed',mblite_access_private.scope_for(sc) is not null and exists(select 1 from public.mblite_books where id=sc) and (admin or exists(select 1 from mblite_access_private.entitlements where user_id=u and scope in (mblite_access_private.scope_for(sc),sc))));
 elsif p_action='redeem' then
 insert into mblite_access_private.attempts(user_id,attempts) values(u,1) on conflict(user_id) do update set attempts=case when mblite_access_private.attempts.window_at < now()-interval '15 minutes' then 1 else mblite_access_private.attempts.attempts+1 end,window_at=case when mblite_access_private.attempts.window_at < now()-interval '15 minutes' then now() else mblite_access_private.attempts.window_at end returning attempts into n;
 if n>10 then return jsonb_build_object('ok',false,'error','Muitas tentativas. Aguarde 15 minutos.'); end if;
 c:=upper(btrim(coalesce(p_data->>'code','')));
 if c !~ '^MB-[0-9A-F]{32}$' then return jsonb_build_object('ok',false,'error','Chave inválida ou já utilizada.'); end if;
 select * into k from mblite_access_private.keys where code_hash=sha256(convert_to(c,'UTF8')) for update;
 if not found or k.revoked_at is not null or k.redeemed_at is not null or (k.assigned_to is not null and k.assigned_to<>u) then return jsonb_build_object('ok',false,'error','Chave inválida ou já utilizada.'); end if;
 if exists(select 1 from mblite_access_private.entitlements where user_id=u and scope in (mblite_access_private.scope_for(k.scope),k.scope)) then return jsonb_build_object('ok',false,'error','Sua conta já possui este acesso. A chave não foi consumida.'); end if;
 insert into mblite_access_private.entitlements(user_id,scope) values(u,k.scope) on conflict do nothing;
 get diagnostics n=row_count;
 if n=0 then return jsonb_build_object('ok',false,'error','Sua conta já possui este acesso.'); end if;
 update mblite_access_private.keys set redeemed_by=u,redeemed_at=now() where id=k.id;
 update mblite_access_private.key_requests set issued_code=null where key_id=k.id;
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
 if sc is null or (sc not in ('op-all','t20-all','3det-all','pf2e-all','dnd-all') and (mblite_access_private.scope_for(sc) is null or not exists(select 1 from public.mblite_books where id=sc))) then return jsonb_build_object('ok',false,'error','Escopo inválido.'); end if;
 c:='MB-'||upper(replace(gen_random_uuid()::text,'-',''));
 insert into mblite_access_private.keys(scope,code_hash,code_hint,created_by) values(sc,sha256(convert_to(c,'UTF8')),right(c,6),u) returning id into t;
 return jsonb_build_object('ok',true,'code',c,'id',t);
 elsif p_action='admin_list' then
 return jsonb_build_object('ok',true,'keys',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select ky.id,ky.scope,ky.code_hint,ky.created_at,ky.redeemed_at,ky.revoked_at,au.email as redeemed_email from mblite_access_private.keys ky left join auth.users au on au.id=ky.redeemed_by order by ky.created_at desc limit 200)x),'[]'::jsonb),'tickets',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from (select tk.id,tk.category,tk.platform,tk.contact,tk.message,tk.status,tk.created_at,au.email as account_email from mblite_access_private.tickets tk left join auth.users au on au.id=tk.user_id order by (tk.status='novo') desc,tk.created_at desc limit 200)x),'[]'::jsonb),'counts',jsonb_build_object('active',(select count(*) from mblite_access_private.keys where redeemed_at is null and revoked_at is null),'used',(select count(*) from mblite_access_private.keys where redeemed_at is not null),'revoked',(select count(*) from mblite_access_private.keys where revoked_at is not null),'accounts',(select count(distinct user_id) from mblite_access_private.entitlements),'new_tickets',(select count(*) from mblite_access_private.tickets where status='novo')));
 elsif p_action='revoke_key' then
 update mblite_access_private.keys set revoked_at=now() where id::text=p_data->>'id' and redeemed_at is null and revoked_at is null; get diagnostics n=row_count;
 if n=1 then update mblite_access_private.key_requests set issued_code=null where key_id::text=p_data->>'id'; end if;
 return jsonb_build_object('ok',n=1,'error',case when n=0 then 'Chave não está ativa.' end);
 elsif p_action='ticket_status' then
 st:=p_data->>'status'; if st is null or st not in ('novo','em atendimento','encerrado') then return jsonb_build_object('ok',false,'error','Status inválido.'); end if;
 update mblite_access_private.tickets set status=st,updated_at=now() where id::text=p_data->>'id'; get diagnostics n=row_count;
 return jsonb_build_object('ok',n=1,'error',case when n=0 then 'Chamado não encontrado.' end);
 end if;
 return jsonb_build_object('ok',false,'error','Operação inválida.');
end $$;
notify pgrst,'reload schema';