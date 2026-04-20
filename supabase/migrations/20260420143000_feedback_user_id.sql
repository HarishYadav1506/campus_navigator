-- Move feedback ownership to Supabase Auth user id.
alter table if exists public.feedback_entries
  add column if not exists user_id uuid;

create index if not exists feedback_entries_user_id_idx
  on public.feedback_entries(user_id);
