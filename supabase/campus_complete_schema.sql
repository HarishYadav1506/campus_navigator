-- =============================================================================
-- Campus Navigator — COMPLETE SCHEMA (idempotent)
-- Run in Supabase SQL Editor. Safe to re-run: creates missing objects & adds columns.
-- Order respects foreign keys. Review errors if your DB already differs (e.g. users PK).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Auth / signup helpers
-- -----------------------------------------------------------------------------
create table if not exists public.users (
  email text primary key,
  password text not null,
  role text not null default 'student',
  name text,
  created_at timestamptz not null default now()
);

create table if not exists public.professors_login (
  email text primary key
);

create table if not exists public.admin_login (
  email text primary key
);

insert into public.admin_login (email)
values ('admin@campus.local')
on conflict (email) do nothing;

alter table public.admin_login enable row level security;
drop policy if exists "admin_login_select" on public.admin_login;
create policy "admin_login_select"
  on public.admin_login for select using (true);

-- -----------------------------------------------------------------------------
-- OTP signup RPC (updates existing users row by JWT email)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- Profiles & chat
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_group boolean not null default true,
  type text not null default 'office_hours',
  class_code text,
  created_by_email text,
  max_members int default 50,
  message_start_hour int,
  message_end_hour int,
  office_hours_start timestamptz,
  office_hours_end timestamptz,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.chat_rooms add column if not exists description text;
alter table public.chat_rooms add column if not exists created_by_email text;
alter table public.chat_rooms add column if not exists office_hours_start timestamptz;
alter table public.chat_rooms add column if not exists office_hours_end timestamptz;
alter table public.chat_rooms add column if not exists is_pinned boolean not null default false;

create unique index if not exists chat_rooms_class_code_upper
  on public.chat_rooms (upper(trim(class_code)))
  where class_code is not null and length(trim(class_code)) > 0;

create table if not exists public.chat_room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member',
  unique (room_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  sender_email text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_room_created
  on public.chat_messages (room_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Announcements, approvals, activity
-- -----------------------------------------------------------------------------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null check (category in ('sports','events','seminars','notices')),
  created_by text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  request_type text not null,
  reference_id text,
  requester_email text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  notes text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists public.student_activity (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  action text not null,
  meta jsonb,
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Navigation: places (app also reads place_name, node) + optional nodes/edges graph
-- -----------------------------------------------------------------------------
create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  image text,
  created_at timestamptz not null default now()
);

alter table public.places add column if not exists place_name text;
alter table public.places add column if not exists node int;

create table if not exists public.place_nodes (
  node_id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade
);

create table if not exists public.place_edges (
  id uuid primary key default gen_random_uuid(),
  from_node uuid not null references public.place_nodes(node_id) on delete cascade,
  to_node uuid not null references public.place_nodes(node_id) on delete cascade,
  distance int not null default 1,
  unique(from_node, to_node)
);

-- Integer graph (NavigationService fallback)
create table if not exists public.nodes (
  id bigserial primary key,
  node int not null unique,
  place_name text not null,
  image text
);

create table if not exists public.edges (
  id bigserial primary key,
  node_from int not null,
  node_to int not null,
  unique(node_from, node_to)
);

-- -----------------------------------------------------------------------------
-- Feedback (course + app) + professor link for course rows
-- -----------------------------------------------------------------------------
create table if not exists public.feedback_entries (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  feedback_type text not null check (feedback_type in ('course','app')),
  subject text not null,
  message text not null,
  course_code text,
  professor_email text,
  rating int check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

alter table public.feedback_entries add column if not exists professor_email text;

-- -----------------------------------------------------------------------------
-- TPO
-- -----------------------------------------------------------------------------
create table if not exists public.tpo_postings (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  role text not null,
  description text not null,
  eligibility text,
  available_slots int not null default 0 check (available_slots >= 0),
  created_by text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.tpo_applications (
  id uuid primary key default gen_random_uuid(),
  posting_id uuid not null references public.tpo_postings(id) on delete cascade,
  student_email text not null,
  status text not null default 'applied' check (status in ('applied','shortlisted','rejected','selected')),
  created_at timestamptz not null default now(),
  unique(posting_id, student_email)
);

-- -----------------------------------------------------------------------------
-- Professor slots & bookings
-- -----------------------------------------------------------------------------
create table if not exists public.prof_slots (
  id uuid primary key default gen_random_uuid(),
  prof_email text not null,
  prof_name text not null,
  day text not null,
  start_time text not null,
  end_time text not null,
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.prof_slots add column if not exists created_at timestamptz not null default now();

create table if not exists public.prof_slot_bookings (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid not null references public.prof_slots(id) on delete cascade,
  student_email text not null,
  status text not null default 'requested' check (status in ('requested','approved','rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique(slot_id, student_email)
);

-- -----------------------------------------------------------------------------
-- Events & seminars (used by app; not in older migrations)
-- -----------------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null,
  location text not null,
  description text not null default '',
  date_time timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.seminars (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  speaker text not null default '',
  venue text not null default '',
  date_time timestamptz not null,
  created_by text,
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Sports
-- -----------------------------------------------------------------------------
create table if not exists public.sports_arenas (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.sports_bookings (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  status text not null default 'pending',
  booking_time timestamptz,
  checked_in_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.sports_bookings add column if not exists approved_at timestamptz;
alter table public.sports_bookings add column if not exists checkin_deadline timestamptz;
alter table public.sports_bookings add column if not exists ends_at timestamptz;
alter table public.sports_bookings add column if not exists checked_in_at timestamptz;
alter table public.sports_bookings add column if not exists created_at timestamptz not null default now();

create table if not exists public.sports_waitlist (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.sports_admin_notifications (
  id uuid primary key default gen_random_uuid(),
  arena_name text not null,
  user_email text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.sports_cooldowns (
  user_email text primary key,
  blocked_until timestamptz not null
);

update public.sports_bookings
set booking_time = coalesce(booking_time, created_at)
where booking_time is null;

-- -----------------------------------------------------------------------------
-- IP / BTP
-- -----------------------------------------------------------------------------
create table if not exists public.ip_btp_slots (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  details text not null default '',
  professor_email text not null default '',
  cgpa_cap numeric,
  created_at timestamptz not null default now()
);

create table if not exists public.ip_btp_requests (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid references public.ip_btp_slots (id) on delete cascade,
  student_name text not null,
  student_email text not null,
  student_cg numeric not null,
  description text not null,
  professor_email text,
  created_at timestamptz not null default now()
);

alter table public.ip_btp_requests add column if not exists status text;
alter table public.ip_btp_requests add column if not exists reviewed_at timestamptz;

update public.ip_btp_requests
set status = 'pending'
where status is null
   or btrim(status) = ''
   or lower(btrim(status)) not in ('pending', 'approved', 'rejected');

alter table public.ip_btp_requests alter column status set default 'pending';

do $$
begin
  alter table public.ip_btp_requests alter column status set not null;
exception
  when others then null;
end $$;

alter table public.ip_btp_requests drop constraint if exists ip_btp_requests_status_check;

alter table public.ip_btp_requests
  add constraint ip_btp_requests_status_check
  check (
    status = any (
      array['pending'::text, 'approved'::text, 'rejected'::text]
    )
  );

-- -----------------------------------------------------------------------------
-- Notifications (in-app)
-- -----------------------------------------------------------------------------
create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  title text not null,
  body text,
  kind text not null default 'general',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_notifications_email_created
  on public.user_notifications (user_email, created_at desc);

-- -----------------------------------------------------------------------------
-- Engagement / points (optional RPC used by app)
-- -----------------------------------------------------------------------------
create table if not exists public.user_stats (
  user_email text primary key,
  points int not null default 0,
  streak int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.point_ledger (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  delta int not null,
  reason text not null,
  created_at timestamptz not null default now()
);

create or replace function public.engagement_award_points(p_email text, p_delta int, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  e text := lower(trim(p_email));
begin
  if e = '' or p_delta = 0 then
    return;
  end if;
  insert into public.point_ledger (user_email, delta, reason) values (e, p_delta, p_reason);
  insert into public.user_stats (user_email, points, streak, updated_at)
  values (e, greatest(0, p_delta), 0, now())
  on conflict (user_email) do update set
    points = greatest(0, public.user_stats.points + p_delta),
    updated_at = now();
end;
$$;

grant execute on function public.engagement_award_points(text, int, text) to anon, authenticated;

create table if not exists public.campus_feedback (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  subject text not null,
  message text not null,
  rating int check (rating is null or (rating >= 1 and rating <= 5)),
  created_at timestamptz not null default now()
);

create table if not exists public.user_interests (
  user_email text not null,
  tag text not null,
  weight int not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_email, tag)
);

-- =============================================================================
-- ROW LEVEL SECURITY — permissive policies (anon + authenticated; custom app auth)
-- =============================================================================

alter table public.users enable row level security;
drop policy if exists "users_insert_authenticated_own_email" on public.users;
create policy "users_insert_authenticated_own_email"
  on public.users for insert to authenticated
  with check (lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', ''))));
drop policy if exists "users_select_authenticated_own" on public.users;
create policy "users_select_authenticated_own"
  on public.users for select to authenticated
  using (lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', ''))));
drop policy if exists "users_update_authenticated_own" on public.users;
create policy "users_update_authenticated_own"
  on public.users for update to authenticated
  using (lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', ''))))
  with check (lower(btrim(email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', ''))));
drop policy if exists "users_select_anon_login" on public.users;
create policy "users_select_anon_login"
  on public.users for select to anon using (true);

-- Tables: open policies
alter table public.profiles enable row level security;
drop policy if exists "profiles_all" on public.profiles;
create policy "profiles_all" on public.profiles for all using (true) with check (true);

alter table public.chat_rooms enable row level security;
drop policy if exists "chat_rooms_all" on public.chat_rooms;
create policy "chat_rooms_all" on public.chat_rooms for all using (true) with check (true);

alter table public.chat_room_members enable row level security;
drop policy if exists "chat_room_members_all" on public.chat_room_members;
create policy "chat_room_members_all" on public.chat_room_members for all using (true) with check (true);

alter table public.chat_messages enable row level security;
drop policy if exists "chat_messages_all" on public.chat_messages;
create policy "chat_messages_all" on public.chat_messages for all using (true) with check (true);

alter table public.announcements enable row level security;
drop policy if exists "ann_all" on public.announcements;
create policy "ann_all" on public.announcements for all using (true) with check (true);

alter table public.approval_requests enable row level security;
drop policy if exists "approval_all" on public.approval_requests;
create policy "approval_all" on public.approval_requests for all using (true) with check (true);

alter table public.student_activity enable row level security;
drop policy if exists "act_all" on public.student_activity;
create policy "act_all" on public.student_activity for all using (true) with check (true);

alter table public.places enable row level security;
drop policy if exists "places_all" on public.places;
create policy "places_all" on public.places for all using (true) with check (true);

alter table public.place_nodes enable row level security;
drop policy if exists "nodes_all" on public.place_nodes;
create policy "nodes_all" on public.place_nodes for all using (true) with check (true);

alter table public.place_edges enable row level security;
drop policy if exists "edges_all" on public.place_edges;
create policy "edges_all" on public.place_edges for all using (true) with check (true);

alter table public.nodes enable row level security;
drop policy if exists "nodes_int_all" on public.nodes;
create policy "nodes_int_all" on public.nodes for all using (true) with check (true);

alter table public.edges enable row level security;
drop policy if exists "edges_int_all" on public.edges;
create policy "edges_int_all" on public.edges for all using (true) with check (true);

alter table public.feedback_entries enable row level security;
drop policy if exists "feedback_all" on public.feedback_entries;
create policy "feedback_all" on public.feedback_entries for all using (true) with check (true);

alter table public.tpo_postings enable row level security;
drop policy if exists "tpo_posting_all" on public.tpo_postings;
create policy "tpo_posting_all" on public.tpo_postings for all using (true) with check (true);

alter table public.tpo_applications enable row level security;
drop policy if exists "tpo_app_all" on public.tpo_applications;
create policy "tpo_app_all" on public.tpo_applications for all using (true) with check (true);

alter table public.prof_slots enable row level security;
drop policy if exists "prof_slots_all" on public.prof_slots;
create policy "prof_slots_all" on public.prof_slots for all using (true) with check (true);

alter table public.prof_slot_bookings enable row level security;
drop policy if exists "slot_booking_all" on public.prof_slot_bookings;
create policy "slot_booking_all" on public.prof_slot_bookings for all using (true) with check (true);

alter table public.events enable row level security;
drop policy if exists "events_all" on public.events;
create policy "events_all" on public.events for all using (true) with check (true);

alter table public.seminars enable row level security;
drop policy if exists "seminars_all" on public.seminars;
create policy "seminars_all" on public.seminars for all using (true) with check (true);

alter table public.sports_arenas enable row level security;
drop policy if exists "sports_arenas_all" on public.sports_arenas;
create policy "sports_arenas_all" on public.sports_arenas for all using (true) with check (true);

alter table public.sports_bookings enable row level security;
drop policy if exists "sports_bookings_all" on public.sports_bookings;
create policy "sports_bookings_all" on public.sports_bookings for all using (true) with check (true);

alter table public.sports_waitlist enable row level security;
drop policy if exists "sports_waitlist_all" on public.sports_waitlist;
create policy "sports_waitlist_all" on public.sports_waitlist for all using (true) with check (true);

alter table public.sports_admin_notifications enable row level security;
drop policy if exists "sports_admin_notif_all" on public.sports_admin_notifications;
create policy "sports_admin_notif_all" on public.sports_admin_notifications for all using (true) with check (true);

alter table public.sports_cooldowns enable row level security;
drop policy if exists "sports_cooldowns_all" on public.sports_cooldowns;
create policy "sports_cooldowns_all" on public.sports_cooldowns for all using (true) with check (true);

alter table public.ip_btp_slots enable row level security;
drop policy if exists "ip_btp_slots_all" on public.ip_btp_slots;
create policy "ip_btp_slots_all" on public.ip_btp_slots for all using (true) with check (true);

alter table public.ip_btp_requests enable row level security;
drop policy if exists "ip_btp_requests_all" on public.ip_btp_requests;
create policy "ip_btp_requests_all" on public.ip_btp_requests for all using (true) with check (true);

alter table public.user_notifications enable row level security;
drop policy if exists "user_notifications_select" on public.user_notifications;
create policy "user_notifications_select" on public.user_notifications for select using (true);
drop policy if exists "user_notifications_insert" on public.user_notifications;
create policy "user_notifications_insert" on public.user_notifications for insert with check (true);
drop policy if exists "user_notifications_update" on public.user_notifications;
create policy "user_notifications_update" on public.user_notifications for update using (true);

alter table public.user_stats enable row level security;
drop policy if exists "user_stats_all" on public.user_stats;
create policy "user_stats_all" on public.user_stats for all using (true) with check (true);

alter table public.point_ledger enable row level security;
drop policy if exists "point_ledger_all" on public.point_ledger;
create policy "point_ledger_all" on public.point_ledger for all using (true) with check (true);

alter table public.campus_feedback enable row level security;
drop policy if exists "campus_feedback_insert" on public.campus_feedback;
create policy "campus_feedback_insert" on public.campus_feedback for insert with check (true);
drop policy if exists "campus_feedback_read" on public.campus_feedback;
create policy "campus_feedback_read" on public.campus_feedback for select using (true);

alter table public.user_interests enable row level security;
drop policy if exists "user_interests_all" on public.user_interests;
create policy "user_interests_all" on public.user_interests for all using (true) with check (true);

alter table public.professors_login enable row level security;
drop policy if exists "professors_login_all" on public.professors_login;
create policy "professors_login_all" on public.professors_login for all using (true) with check (true);

-- =============================================================================
-- Done
-- =============================================================================
