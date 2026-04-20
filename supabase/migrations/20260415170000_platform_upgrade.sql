-- Platform upgrade: roles, admin modules, navigation graph, feedback, TPO, slots.

-- -----------------------------
-- USERS / PROFILE HELPERS
-- -----------------------------
alter table if exists public.users
  add column if not exists name text;

-- -----------------------------
-- ADMIN ANNOUNCEMENTS
-- -----------------------------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null check (category in ('sports','events','seminars','notices')),
  created_by text not null,
  created_at timestamptz not null default now()
);

-- -----------------------------
-- APPROVAL REQUESTS (generic)
-- -----------------------------
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

-- -----------------------------
-- STUDENT ACTIVITY LOG
-- -----------------------------
create table if not exists public.student_activity (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  action text not null,
  meta jsonb,
  created_at timestamptz not null default now()
);

-- -----------------------------
-- CAMPUS NAVIGATION GRAPH
-- -----------------------------
create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  image text,
  created_at timestamptz not null default now()
);

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

-- -----------------------------
-- FEEDBACK
-- -----------------------------
create table if not exists public.feedback_entries (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  feedback_type text not null check (feedback_type in ('course','app')),
  subject text not null,
  message text not null,
  course_code text,
  rating int check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

-- -----------------------------
-- TPO / PLACEMENTS
-- -----------------------------
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

-- -----------------------------
-- PROFESSOR SLOTS + BOOKINGS
-- -----------------------------
alter table if exists public.prof_slots
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.prof_slot_bookings (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid not null references public.prof_slots(id) on delete cascade,
  student_email text not null,
  status text not null default 'requested' check (status in ('requested','approved','rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique(slot_id, student_email)
);

-- -----------------------------
-- SPORTS SAFE FIELDS
-- -----------------------------
alter table if exists public.sports_bookings
  add column if not exists approved_at timestamptz,
  add column if not exists checkin_deadline timestamptz,
  add column if not exists ends_at timestamptz,
  add column if not exists checked_in_at timestamptz;

create table if not exists public.sports_cooldowns (
  user_email text primary key,
  blocked_until timestamptz not null
);

-- -----------------------------
-- RLS (permissive for current custom-auth app)
-- -----------------------------
alter table public.announcements enable row level security;
alter table public.approval_requests enable row level security;
alter table public.student_activity enable row level security;
alter table public.places enable row level security;
alter table public.place_nodes enable row level security;
alter table public.place_edges enable row level security;
alter table public.feedback_entries enable row level security;
alter table public.tpo_postings enable row level security;
alter table public.tpo_applications enable row level security;
alter table public.prof_slot_bookings enable row level security;

drop policy if exists "ann_all" on public.announcements;
create policy "ann_all" on public.announcements for all using (true) with check (true);
drop policy if exists "approval_all" on public.approval_requests;
create policy "approval_all" on public.approval_requests for all using (true) with check (true);
drop policy if exists "act_all" on public.student_activity;
create policy "act_all" on public.student_activity for all using (true) with check (true);
drop policy if exists "places_all" on public.places;
create policy "places_all" on public.places for all using (true) with check (true);
drop policy if exists "nodes_all" on public.place_nodes;
create policy "nodes_all" on public.place_nodes for all using (true) with check (true);
drop policy if exists "edges_all" on public.place_edges;
create policy "edges_all" on public.place_edges for all using (true) with check (true);
drop policy if exists "feedback_all" on public.feedback_entries;
create policy "feedback_all" on public.feedback_entries for all using (true) with check (true);
drop policy if exists "tpo_posting_all" on public.tpo_postings;
create policy "tpo_posting_all" on public.tpo_postings for all using (true) with check (true);
drop policy if exists "tpo_app_all" on public.tpo_applications;
create policy "tpo_app_all" on public.tpo_applications for all using (true) with check (true);
drop policy if exists "slot_booking_all" on public.prof_slot_bookings;
create policy "slot_booking_all" on public.prof_slot_bookings for all using (true) with check (true);
