-- Fix: "new row violates row-level security policy for table users" after OTP verify.
-- After verifyOTP the client uses the authenticated role; inserts must allow
-- rows where public.users.email matches the Supabase Auth email claim.

alter table public.users enable row level security;

drop policy if exists "users_insert_authenticated_own_email" on public.users;
create policy "users_insert_authenticated_own_email"
  on public.users
  for insert
  to authenticated
  with check (
    lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', '')))
  );

drop policy if exists "users_select_authenticated_own" on public.users;
create policy "users_select_authenticated_own"
  on public.users
  for select
  to authenticated
  using (
    lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', '')))
  );

drop policy if exists "users_update_authenticated_own" on public.users;
create policy "users_update_authenticated_own"
  on public.users
  for update
  to authenticated
  using (
    lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', '')))
  )
  with check (
    lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', '')))
  );

-- Password login uses the anon key without a session (existing app behavior).
-- Note: SELECT for anon is permissive; consider moving login to a SECURITY DEFINER RPC later.
drop policy if exists "users_select_anon_login" on public.users;
create policy "users_select_anon_login"
  on public.users
  for select
  to anon
  using (true);
