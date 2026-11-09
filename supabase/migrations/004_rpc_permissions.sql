-- Harden only the new FlockWise functions; leave existing application functions unchanged.
revoke execute on function public.org_role(uuid),public.can_read_record(uuid,text,uuid,jsonb),public.can_write_record(uuid,text,uuid,jsonb),public.create_organization(text),public.accept_invitations(),public.reserve_ai(uuid) from public,anon;
grant execute on function public.org_role(uuid),public.can_read_record(uuid,text,uuid,jsonb),public.can_write_record(uuid,text,uuid,jsonb),public.create_organization(text),public.accept_invitations(),public.reserve_ai(uuid) to authenticated;
revoke execute on function public.validate_record(),public.audit_record(),public.validate_inventory(),public.audit_access(),public.validate_contract_record(),public.validate_consumed_feed() from public,anon,authenticated;
