-- Retire the recently introduced Shed checkpoints feature without deleting history.
-- Existing Daily SOP/photo checkpoints and all records/storage permissions are untouched.
do $$
declare job record; object record;
begin
 for job in select jobid from cron.job where jobname in ('flockwise-checkpoint-evaluate','flockwise-checkpoint-push') loop
  perform cron.unschedule(job.jobid);
 end loop;
 for object in select c.oid::regclass as name from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname like 'cp\_%' escape '\' and c.relkind in ('r','p') loop
  execute format('revoke all on table %s from public,anon,authenticated',object.name);
 end loop;
 for object in select p.oid::regprocedure as name from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'cp\_%' escape '\' loop
  execute format('revoke all on function %s from public,anon,authenticated',object.name);
 end loop;
end $$;
update public.cp_push_subscriptions set enabled=false where enabled;
update public.cp_notifications set push_status='feature_removed' where push_status in ('not_enabled','retry','sending');
