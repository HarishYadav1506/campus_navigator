-- IP/BTP: track application outcome (pending / approved / rejected) for professors and students.

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

alter table public.ip_btp_requests
  add column if not exists status text;

alter table public.ip_btp_requests
  add column if not exists reviewed_at timestamptz;

update public.ip_btp_requests
set status = 'pending'
where status is null
   or btrim(status) = ''
   or lower(btrim(status)) not in ('pending', 'approved', 'rejected');

alter table public.ip_btp_requests
  alter column status set default 'pending';

alter table public.ip_btp_requests
  alter column status set not null;

alter table public.ip_btp_requests
  drop constraint if exists ip_btp_requests_status_check;

alter table public.ip_btp_requests
  add constraint ip_btp_requests_status_check
  check (
    status = any (
      array['pending'::text, 'approved'::text, 'rejected'::text]
    )
  );
