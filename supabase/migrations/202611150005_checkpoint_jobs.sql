create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;
create function public.cp_worker_wake() returns void language plpgsql security definer set search_path=public,extensions as $$ begin
 if exists(select 1 from cp_private_settings where id) then perform net.http_post(url:='https://mhcnpjopukekudvmduzu.supabase.co/functions/v1/checkpoint-worker',headers:=jsonb_build_object('Content-Type','application/json','x-checkpoint-worker',(select value->>'workerSecret' from cp_private_settings where id)),body:='{}'::jsonb,timeout_milliseconds:=10000);end if;
end $$;
revoke all on function cp_worker_wake() from public,anon,authenticated;
select cron.schedule('flockwise-checkpoint-evaluate','* * * * *','select public.cp_tick_all()');
select cron.schedule('flockwise-checkpoint-push','* * * * *','select public.cp_worker_wake()');
