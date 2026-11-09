-- Apply after 001_core.sql. Preserves historical sale events.
create or replace function public.validate_inventory() returns trigger language plpgsql security definer set search_path=public as $$
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

create unique index if not exists unique_daily_sop on public.records(batch_id,(data->>'due'),(data->>'sopKey')) where kind='checkpoint' and data->>'source'='daily_sop';
create or replace function public.validate_contract_record() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.kind='batch' and not exists(select 1 from records s where s.id=(new.data->>'shed')::uuid and s.org_id=new.org_id and s.kind='shed' and s.data->>'farm'=new.data->>'farm') then raise exception 'Shed must belong to selected farm';end if;
 if new.kind='inventory' and new.data->>'type'='company_pickup' and (nullif(trim(new.data->>'company'),'') is null or nullif(trim(new.data->>'reference'),'') is null) then raise exception 'Collecting company and pickup receipt required';end if;
 if new.kind='checkpoint' and new.data->>'source'='daily_sop' then
  if coalesce(new.data->>'sopKey','') not in ('biosecurity','feed-water','environment','litter','mortality','health','records','lighting','brooding','pickup') or coalesce(new.data->>'status','') not in ('Pending','Completed') or nullif(new.data->>'due','') is null then raise exception 'Invalid SOP entry';end if;
  if (new.data->>'due')::date>(now() at time zone (select data->>'timezone' from records where id=new.batch_id))::date or (new.data->>'due')::date<(select (data->>'placement')::date from records where id=new.batch_id) then raise exception 'SOP date outside permitted range';end if;
  if exists(select 1 from records where id=new.batch_id and data->>'status'='Completed') then raise exception 'Completed batch checklist is read-only';end if;
  if new.data->>'status'='Completed' then new.data=jsonb_set(jsonb_set(new.data,'{completedBy}',to_jsonb(auth.uid()::text)),'{completedAt}',to_jsonb(now()));else new.data=new.data||jsonb_build_object('completedBy',null,'completedAt',null);end if;
 end if;
 if TG_OP='UPDATE' and old.kind='checkpoint' and old.data->>'source'='daily_sop' and (new.data->>'source' is distinct from old.data->>'source' or new.data->>'sopKey' is distinct from old.data->>'sopKey' or new.data->>'due' is distinct from old.data->>'due') then raise exception 'SOP identity cannot change';end if;
 return new;
end $$;
create trigger validate_contract_record before insert or update on records for each row execute function validate_contract_record();
revoke execute on function public.validate_contract_record() from public;
