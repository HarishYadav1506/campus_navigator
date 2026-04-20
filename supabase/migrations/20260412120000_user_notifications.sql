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

alter table public.user_notifications enable row level security;

drop policy if exists "user_notifications_select" on public.user_notifications;
create policy "user_notifications_select"
  on public.user_notifications for select using (true);

drop policy if exists "user_notifications_insert" on public.user_notifications;
create policy "user_notifications_insert"
  on public.user_notifications for insert with check (true);

drop policy if exists "user_notifications_update" on public.user_notifications;
create policy "user_notifications_update"
  on public.user_notifications for update using (true);
