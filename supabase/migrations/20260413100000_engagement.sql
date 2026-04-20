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

alter table public.user_stats enable row level security;
alter table public.point_ledger enable row level security;
alter table public.campus_feedback enable row level security;
alter table public.user_interests enable row level security;

drop policy if exists "user_stats_all" on public.user_stats;
create policy "user_stats_all" on public.user_stats for all using (true) with check (true);

drop policy if exists "point_ledger_all" on public.point_ledger;
create policy "point_ledger_all" on public.point_ledger for all using (true) with check (true);

drop policy if exists "campus_feedback_insert" on public.campus_feedback;
create policy "campus_feedback_insert" on public.campus_feedback for insert with check (true);
drop policy if exists "campus_feedback_read" on public.campus_feedback;
create policy "campus_feedback_read" on public.campus_feedback for select using (true);

drop policy if exists "user_interests_all" on public.user_interests;
create policy "user_interests_all" on public.user_interests for all using (true) with check (true);

grant execute on function public.engagement_award_points(text, int, text) to anon, authenticated;
