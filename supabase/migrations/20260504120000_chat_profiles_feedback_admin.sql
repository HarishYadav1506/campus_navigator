-- Profiles (for chat membership), chat tables, feedback professor link, admin_login seed.
-- Safe to re-run: IF NOT EXISTS / IF NOT EXISTS columns.

-- ---------------------------------------------------------------------------
-- profiles (chat_room_members.user_id)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- chat_rooms
-- ---------------------------------------------------------------------------
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
  created_at timestamptz not null default now()
);

create unique index if not exists chat_rooms_class_code_upper
  on public.chat_rooms (upper(trim(class_code)))
  where class_code is not null and length(trim(class_code)) > 0;

alter table public.chat_rooms
  add column if not exists description text;

alter table public.chat_rooms
  add column if not exists created_by_email text;

alter table public.chat_rooms
  add column if not exists office_hours_start timestamptz;

alter table public.chat_rooms
  add column if not exists office_hours_end timestamptz;

-- ---------------------------------------------------------------------------
-- chat_room_members
-- ---------------------------------------------------------------------------
create table if not exists public.chat_room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member',
  unique (room_id, user_id)
);

-- ---------------------------------------------------------------------------
-- chat_messages
-- ---------------------------------------------------------------------------
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  sender_email text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_room_created
  on public.chat_messages (room_id, created_at desc);

-- ---------------------------------------------------------------------------
-- feedback: professor attribution for course feedback
-- ---------------------------------------------------------------------------
alter table public.feedback_entries
  add column if not exists professor_email text;

-- ---------------------------------------------------------------------------
-- admin_login (optional; app also supports hardcoded admin@campus.local / admin123)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- RLS (permissive — app uses custom SessionManager + anon key)
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_room_members enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "profiles_all" on public.profiles;
create policy "profiles_all"
  on public.profiles for all using (true) with check (true);

drop policy if exists "chat_rooms_all" on public.chat_rooms;
create policy "chat_rooms_all"
  on public.chat_rooms for all using (true) with check (true);

drop policy if exists "chat_room_members_all" on public.chat_room_members;
create policy "chat_room_members_all"
  on public.chat_room_members for all using (true) with check (true);

drop policy if exists "chat_messages_all" on public.chat_messages;
create policy "chat_messages_all"
  on public.chat_messages for all using (true) with check (true);
