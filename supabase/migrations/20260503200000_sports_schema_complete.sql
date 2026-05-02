-- Sports booking: full schema + permissive RLS (matches Flutter sports_status_page + manage_sports).

-- Arenas (one row per court name)
create table if not exists public.sports_arenas (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

-- Bookings / approval workflow
create table if not exists public.sports_bookings (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  status text not null default 'pending',
  booking_time timestamptz,
  checked_in_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.sports_bookings
  add column if not exists approved_at timestamptz;

alter table public.sports_bookings
  add column if not exists checkin_deadline timestamptz;

alter table public.sports_bookings
  add column if not exists ends_at timestamptz;

alter table public.sports_bookings
  add column if not exists created_at timestamptz not null default now();

-- Optional queue when court busy
create table if not exists public.sports_waitlist (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  created_at timestamptz not null default now()
);

-- Admin inbox (dashboard / future use)
create table if not exists public.sports_admin_notifications (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  message text not null,
  created_at timestamptz not null default now()
);

-- Cooldown after missed check-in (column name must match app: blocked_until)
create table if not exists public.sports_cooldowns (
  user_email text primary key,
  blocked_until timestamptz not null
);

-- Backfill booking_time for old pending rows so ordering / admin list behave
update public.sports_bookings
set booking_time = coalesce(booking_time, created_at)
where booking_time is null;

-- ---------- RLS: enabled with open policies (custom SessionManager auth) ----------
alter table public.sports_arenas enable row level security;
alter table public.sports_bookings enable row level security;
alter table public.sports_waitlist enable row level security;
alter table public.sports_admin_notifications enable row level security;
alter table public.sports_cooldowns enable row level security;

drop policy if exists "sports_arenas_all" on public.sports_arenas;
create policy "sports_arenas_all"
  on public.sports_arenas for all using (true) with check (true);

drop policy if exists "sports_bookings_all" on public.sports_bookings;
create policy "sports_bookings_all"
  on public.sports_bookings for all using (true) with check (true);

drop policy if exists "sports_waitlist_all" on public.sports_waitlist;
create policy "sports_waitlist_all"
  on public.sports_waitlist for all using (true) with check (true);

drop policy if exists "sports_admin_notif_all" on public.sports_admin_notifications;
create policy "sports_admin_notif_all"
  on public.sports_admin_notifications for all using (true) with check (true);

drop policy if exists "sports_cooldowns_all" on public.sports_cooldowns;
create policy "sports_cooldowns_all"
  on public.sports_cooldowns for all using (true) with check (true);
