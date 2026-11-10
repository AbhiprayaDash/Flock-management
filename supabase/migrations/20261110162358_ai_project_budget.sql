create table public.ai_project_usage(day date primary key,count integer not null default 0 check(count between 0 and 10));
alter table public.ai_project_usage enable row level security;
revoke all on public.ai_project_usage from anon,authenticated;
create or replace function public.reserve_ai(o uuid) returns boolean language plpgsql security definer set search_path=public as $$
declare d date:=(now() at time zone 'UTC')::date; project_count integer; org_count integer;
begin
 if auth.uid() is null or coalesce(org_role(o),'') not in ('owner','manager','worker','veterinarian') or not exists(select 1 from organizations where id=o and ai_consent) then return false;end if;
 perform pg_advisory_xact_lock(hashtextextended('flockwise-ai-project:'||d::text,0));
 select count into project_count from ai_project_usage where day=d;
 select count into org_count from ai_usage where org_id=o and day=d;
 if coalesce(project_count,0)>=10 or coalesce(org_count,0)>=10 then return false;end if;
 insert into ai_project_usage(day,count) values(d,1) on conflict(day) do update set count=ai_project_usage.count+1;
 insert into ai_usage(org_id,day,count) values(o,d,1) on conflict(org_id,day) do update set count=ai_usage.count+1;
 return true;
end $$;
revoke execute on function public.reserve_ai(uuid) from public,anon;
grant execute on function public.reserve_ai(uuid) to authenticated;
