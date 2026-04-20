-- Reliable signup after email OTP: runs as table owner, bypasses RLS, but only allows
-- the row for the email in the current JWT (cannot spoof another user's email).

create or replace function public.create_user_after_otp(p_password text, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(btrim(coalesce(auth.jwt() ->> 'email', '')));
begin
  if v_email = '' then
    raise exception 'Not authenticated';
  end if;

  if exists (select 1 from public.users u where lower(btrim(u.email)) = v_email) then
    update public.users
    set password = p_password, role = p_role
    where lower(btrim(email)) = v_email;
  else
    insert into public.users (email, password, role)
    values (v_email, p_password, p_role);
  end if;
end;
$$;

revoke all on function public.create_user_after_otp(text, text) from public;
grant execute on function public.create_user_after_otp(text, text) to authenticated;
