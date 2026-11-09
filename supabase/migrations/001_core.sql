-- Run in Supabase SQL editor as project administrator.
create extension if not exists pgcrypto;
create table public.organizations(id uuid primary key default gen_random_uuid(), name text not null, ai_consent boolean not null default false);
create table public.memberships(org_id uuid references public.organizations on delete cascade,user_id uuid references auth.users on delete cascade,role text not null check(role in ('owner','manager','worker','veterinarian','viewer')),primary key(org_id,user_id));
create table public.assignments(org_id uuid not null,user_id uuid not null,shed_id uuid not null,primary key(org_id,user_id,shed_id),foreign key(org_id,user_id) references public.memberships on delete cascade);
create table public.records(id uuid primary key default gen_random_uuid(),org_id uuid not null references public.organizations,kind text not null check(kind in ('farm','shed','batch','log','inventory','feed','vaccination','treatment','checkpoint','case','alert','profile')),batch_id uuid references public.records, data jsonb not null,created_by uuid not null default auth.uid(),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),revision integer not null default 1,unique(id,org_id));
create index records_org_kind on public.records(org_id,kind,batch_id);
create table public.audit(id bigint generated always as identity primary key,org_id uuid not null,actor uuid,record_id uuid,action text,old_data jsonb,new_data jsonb,at timestamptz default now());
create table public.invitations(id uuid primary key default gen_random_uuid(),org_id uuid references public.organizations,email text not null,role text not null check(role in ('manager','worker','veterinarian','viewer')),expires_at timestamptz default now()+interval '7 days',accepted_at timestamptz);
create table public.ai_usage(org_id uuid references public.organizations,day date default current_date,count integer default 0,primary key(org_id,day));
create function public.org_role(o uuid) returns text language sql stable security definer set search_path=public as $$ select role from memberships where org_id=o and user_id=auth.uid() $$;
create function public.can_read_record(o uuid,k text,b uuid,d jsonb) returns boolean language sql stable security definer set search_path=public as $$ select case when org_role(o) in ('owner','manager','viewer') then true when org_role(o)='veterinarian' then k in ('farm','shed','batch','log','vaccination','treatment','case','profile','alert','checkpoint') when org_role(o)='worker' then k='profile' or exists(select 1 from assignments a where a.org_id=o and a.user_id=auth.uid() and ((k='batch' and a.shed_id::text=d->>'shed') or (k not in ('farm','shed','batch','profile') and a.shed_id=(select (r.data->>'shed')::uuid from records r where r.id=b and r.org_id=o and r.kind='batch')))) else false end $$;
create function public.can_write_record(o uuid,k text,b uuid,d jsonb) returns boolean language sql stable security definer set search_path=public as $$ select org_role(o)='owner' or (org_role(o)='manager' and k not in ('profile','treatment')) or (org_role(o)='veterinarian' and k in ('case','vaccination','treatment')) or (org_role(o)='worker' and k in ('log','checkpoint','case') and can_read_record(o,k,b,d)) $$;
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.assignments enable row level security;
alter table public.records enable row level security;
alter table public.audit enable row level security;
alter table public.invitations enable row level security;
alter table public.ai_usage enable row level security;
create policy org_read on organizations for select to authenticated using(org_role(id) is not null);
create policy org_update on organizations for update to authenticated using(org_role(id)='owner') with check(org_role(id)='owner');
create policy member_read on memberships for select to authenticated using(org_role(org_id) is not null);
create policy member_manage on memberships for all to authenticated using(org_role(org_id)='owner' and user_id<>auth.uid()) with check(org_role(org_id)='owner' and user_id<>auth.uid());
create policy assignment_read on assignments for select to authenticated using(org_role(org_id) is not null);
create policy assignment_manage on assignments for all to authenticated using(org_role(org_id) in ('owner','manager')) with check(org_role(org_id) in ('owner','manager'));
create policy records_read on records for select to authenticated using(can_read_record(org_id,kind,batch_id,data));
create policy records_insert on records for insert to authenticated with check(can_write_record(org_id,kind,batch_id,data) and created_by=auth.uid());
create policy records_update on records for update to authenticated using(can_write_record(org_id,kind,batch_id,data)) with check(can_write_record(org_id,kind,batch_id,data));
create policy records_delete on records for delete to authenticated using(org_role(org_id)='owner');
create policy audit_read on audit for select to authenticated using(org_role(org_id) in ('owner','manager','veterinarian'));
create policy invites_manage on invitations for all to authenticated using(org_role(org_id)='owner') with check(org_role(org_id)='owner');
create function public.validate_record() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if TG_OP='UPDATE' then
 if new.org_id<>old.org_id or new.kind<>old.kind or new.batch_id is distinct from old.batch_id or new.created_by<>old.created_by then raise exception 'Record identity cannot change'; end if;
 new.revision=old.revision+1; new.updated_at=now();
 end if;
 if new.batch_id is not null and not exists(select 1 from records where id=new.batch_id and org_id=new.org_id and kind='batch') then raise exception 'Invalid batch'; end if;
 if new.kind in ('log','inventory','feed','vaccination','treatment','checkpoint','case','alert') and new.batch_id is null then raise exception 'Batch required'; end if;
 if new.kind='batch' and not exists(select 1 from records where id=(new.data->>'shed')::uuid and org_id=new.org_id and kind='shed') then raise exception 'Invalid shed'; end if;
 if new.kind='shed' and not exists(select 1 from records where id=(new.data->>'farm')::uuid and org_id=new.org_id and kind='farm') then raise exception 'Invalid farm'; end if;
 if new.kind='log' then
 if exists(select 1 from jsonb_each(new.data) e where e.key in ('feed','water','mortality','culls','weight','remaining','wastage') and e.value<>'null'::jsonb and ((jsonb_typeof(e.value)<>'number') or (e.value::text)::numeric<0)) then raise exception 'Invalid log amount'; end if;
 if coalesce((new.data->>'remaining')::numeric,0)+coalesce((new.data->>'wastage')::numeric,0)>coalesce((new.data->>'feed')::numeric,0) then raise exception 'Feed balance invalid'; end if;
 end if;
 return new;
end $$;
create trigger validate_records before insert or update on records for each row execute function validate_record();
create function public.audit_record() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into audit(org_id,actor,record_id,action,old_data,new_data) values(coalesce(new.org_id,old.org_id),auth.uid(),coalesce(new.id,old.id),TG_OP,case when TG_OP<>'INSERT' then to_jsonb(old) end,case when TG_OP<>'DELETE' then to_jsonb(new) end);return coalesce(new,old);end $$;
create trigger audit_records after insert or update or delete on records for each row execute function audit_record();
create function public.create_organization(org_name text) returns uuid language plpgsql security definer set search_path=public as $$ declare o uuid;begin if auth.uid() is null then raise exception 'Sign in required';end if;insert into organizations(name) values(left(org_name,120)) returning id into o;insert into memberships values(o,auth.uid(),'owner');return o;end $$;
create function public.accept_invitations() returns void language plpgsql security definer set search_path=public as $$ begin insert into memberships(org_id,user_id,role) select org_id,auth.uid(),role from invitations where lower(email)=lower(auth.jwt()->>'email') and expires_at>now() and accepted_at is null on conflict do nothing;update invitations set accepted_at=now() where lower(email)=lower(auth.jwt()->>'email') and expires_at>now() and accepted_at is null;end $$;
create function public.reserve_ai(o uuid) returns boolean language plpgsql security definer set search_path=public as $$ declare n integer;begin if coalesce(org_role(o),'') not in ('owner','manager','veterinarian') or not exists(select 1 from organizations where id=o and ai_consent) then return false;end if;insert into ai_usage(org_id,day,count) values(o,current_date,1) on conflict(org_id,day) do update set count=ai_usage.count+1 where ai_usage.count<10 returning count into n;return n is not null;end $$;
revoke execute on function public.validate_record(),public.audit_record() from public;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('flock-photos','flock-photos',false,5242880,array['image/jpeg','image/png','image/webp']);
-- Object path: organization UUID / batch UUID / random UUID.ext
create policy photos_read on storage.objects for select to authenticated using(bucket_id='flock-photos' and exists(select 1 from public.records r where r.id::text=(storage.foldername(name))[2] and r.org_id::text=(storage.foldername(name))[1] and r.kind='batch' and public.can_read_record(r.org_id,r.kind,r.id,r.data)));
create policy photos_insert on storage.objects for insert to authenticated with check(bucket_id='flock-photos' and exists(select 1 from public.records r where r.id::text=(storage.foldername(name))[2] and r.org_id::text=(storage.foldername(name))[1] and r.kind='batch' and public.can_write_record(r.org_id,'checkpoint',r.id,r.data)));
create policy photos_delete on storage.objects for delete to authenticated using(bucket_id='flock-photos' and public.org_role(((storage.foldername(name))[1])::uuid)='owner');
-- Lock a batch while validating inventory, including concurrent corrections.
create function public.validate_inventory() returns trigger language plpgsql security definer set search_path=public as $$
declare target uuid; placed numeric; losses numeric; incoming numeric; outgoing numeric;
begin
 if new.kind not in ('log','inventory','batch') then return new;end if;
 target=case when new.kind='batch' then new.id else new.batch_id end;
 perform pg_advisory_xact_lock(hashtextextended(target::text,0));
 if new.kind='log' and exists(select 1 from jsonb_each(new.data) e where e.key in ('mortality','culls') and e.value<>'null'::jsonb and mod((e.value::text)::numeric,1)<>0) then raise exception 'Losses must be whole birds';end if;
 if new.kind='inventory' and (coalesce(new.data->>'type','') not in ('placement','transfer_in','transfer_out','company_pickup','sale','removal') or coalesce((new.data->>'birds')::numeric,0)<=0 or mod((new.data->>'birds')::numeric,1)<>0) then raise exception 'Invalid inventory event';end if;
 if new.kind='batch' then placed=(new.data->>'placed')::numeric;else select (data->>'placed')::numeric into placed from records where id=target;end if;
 if placed is null or placed<=0 or mod(placed,1)<>0 then raise exception 'Positive whole placement required';end if;
 select coalesce(sum(coalesce((d->>'mortality')::numeric,0)+coalesce((d->>'culls')::numeric,0)),0) into losses from (select data d from records where batch_id=target and kind='log' and id<>new.id union all select new.data where new.kind='log') q;
 select coalesce(sum(case when d->>'type' in ('placement','transfer_in') then (d->>'birds')::numeric else 0 end),0),coalesce(sum(case when d->>'type' in ('company_pickup','sale','transfer_out','removal') then (d->>'birds')::numeric else 0 end),0) into incoming,outgoing from (select data d from records where batch_id=target and kind='inventory' and id<>new.id union all select new.data where new.kind='inventory') q;
 if placed+incoming-losses-outgoing<0 then raise exception 'Bird movements exceed inventory';end if;
 return new;
end $$;
create trigger validate_inventory before insert or update on records for each row execute function validate_inventory();
create function public.audit_access() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into audit(org_id,actor,action,old_data,new_data) values(coalesce(new.org_id,old.org_id),auth.uid(),TG_TABLE_NAME||':'||TG_OP,case when TG_OP<>'INSERT' then to_jsonb(old) end,case when TG_OP<>'DELETE' then to_jsonb(new) end);return coalesce(new,old);end $$;
create trigger audit_memberships after insert or update or delete on memberships for each row execute function audit_access();
create trigger audit_assignments after insert or update or delete on assignments for each row execute function audit_access();
create trigger audit_invitations after insert or update or delete on invitations for each row execute function audit_access();
revoke execute on function public.validate_inventory(),public.audit_access() from public;
