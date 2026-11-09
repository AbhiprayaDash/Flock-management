-- Email/password signup does not prove email ownership. Farm membership needs a private invitation token.
revoke execute on function public.accept_invitations() from public,anon,authenticated;
create or replace function public.accept_invitation(invitation_token uuid) returns void language plpgsql security definer set search_path=public as $$
declare invite public.invitations%rowtype;
begin
 if auth.uid() is null then raise exception 'Sign in required';end if;
 select * into invite from public.invitations where id=invitation_token and lower(email)=lower(auth.jwt()->>'email') and expires_at>now() and accepted_at is null for update;
 if not found then raise exception 'Invitation invalid, expired or already used';end if;
 insert into public.memberships(org_id,user_id,role) values(invite.org_id,auth.uid(),invite.role) on conflict do nothing;
 update public.invitations set accepted_at=now() where id=invite.id;
end $$;
revoke execute on function public.accept_invitation(uuid) from public,anon,authenticated;
grant execute on function public.accept_invitation(uuid) to authenticated;
