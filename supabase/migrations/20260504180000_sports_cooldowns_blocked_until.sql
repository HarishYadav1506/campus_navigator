-- Some databases created sports_cooldowns before blocked_until existed.
alter table if exists public.sports_cooldowns
  add column if not exists blocked_until timestamptz;
