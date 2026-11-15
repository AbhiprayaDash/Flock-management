-- Farm-local configuration dates and reporting context, under existing record RLS.
create or replace function public.cp_context(b uuid) returns jsonb language plpgsql stable security invoker set search_path=public as $$
declare r records; f records;
begin
 select * into r from records where id=b and kind='batch';
 if not cp_access(r.org_id,b) then raise exception 'Not accessible';end if;
 select * into f from records where id=(r.data->>'farm')::uuid;
 return jsonb_build_object('farm',r.data->>'farm','shed',r.data->>'shed','farmName',f.data->>'name','shedName',(select data->>'name' from records where id=(r.data->>'shed')::uuid),'batchName',r.data->>'name','timezone',coalesce(f.data->>'timezone',r.data->>'timezone','Asia/Kolkata'));
end $$;
