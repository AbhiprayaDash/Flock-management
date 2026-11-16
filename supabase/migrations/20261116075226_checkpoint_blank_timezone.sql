-- Blank optional farm timezones inherit the batch/scope timezone before the default.
-- Preserve function authorization, grants, snapshots and all farm records.
do $$
declare signature text; definition text; old_expression text; new_expression text;
begin
 for signature,old_expression,new_expression in select * from (values
 ('public.cp_context(uuid)',
  'coalesce(f.data->>''timezone'',r.data->>''timezone'',''Asia/Kolkata'')',
  'coalesce(nullif(btrim(f.data->>''timezone''),''''),nullif(btrim(r.data->>''timezone''),''''),''Asia/Kolkata'')'),
 ('public.cp_save_schedule(uuid,jsonb,uuid,integer)',
  'coalesce(targetfarm.data->>''timezone'',r.data->>''timezone'',''Asia/Kolkata'')',
  'coalesce(nullif(btrim(targetfarm.data->>''timezone''),''''),nullif(btrim(r.data->>''timezone''),''''),''Asia/Kolkata'')')
 ) as changes(signature,old_expression,new_expression)
 loop
  definition=pg_get_functiondef(signature::regprocedure);
  if position(old_expression in definition)=0 then raise exception 'Expected timezone expression missing in %',signature;end if;
  execute replace(definition,old_expression,new_expression);
 end loop;
end $$;
