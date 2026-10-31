-- IMMORTAL SOLUTION Business Suite schema
-- Apply only after confirming this is the intended, active Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.staff_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','staff')),
  created_at timestamptz not null default now()
);
create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  email text not null check (char_length(email) <= 254),
  phone text check (phone is null or char_length(phone) <= 40),
  service text not null default 'General enquiry' check (char_length(service) <= 100),
  message text not null check (char_length(message) between 5 and 5000),
  status text not null default 'new' check (status in ('new','contacted','qualified','converted','closed','spam')),
  staff_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 4 and 180),
  slug text not null unique,
  property_type text not null default 'Residential',
  city text not null default 'Kolkata',
  locality text not null default '',
  price_label text not null default 'Contact for price',
  area_label text not null default '',
  description text not null default '',
  image_url text not null default '',
  status text not null default 'draft' check (status in ('draft','published','sold','rented','archived')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 4 and 180),
  location text not null default 'Kolkata',
  employment_type text not null default 'Full-time',
  category text not null default 'General',
  salary_label text not null default 'As per experience',
  description text not null default '',
  status text not null default 'draft' check (status in ('draft','published','closed')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.job_applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete set null,
  candidate_name text not null check (char_length(candidate_name) between 2 and 120),
  email text not null check (char_length(email) <= 254),
  phone text not null check (char_length(phone) between 7 and 40),
  cover_note text not null default '',
  status text not null default 'new' check (status in ('new','reviewing','shortlisted','rejected','placed')),
  staff_notes text not null default '',
  created_at timestamptz not null default now()
);
create table if not exists public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 4 and 180),
  slug text not null unique,
  excerpt text not null default '',
  body text not null default '',
  category text not null default 'Company News',
  status text not null default 'draft' check (status in ('draft','published','archived')),
  published_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.follow_up_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 180),
  due_date date,
  status text not null default 'open' check (status in ('open','in_progress','done','cancelled')),
  related_lead_id uuid references public.contact_messages(id) on delete set null,
  assigned_to uuid references auth.users(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists contact_messages_created_idx on public.contact_messages(created_at desc);
create index if not exists contact_messages_status_idx on public.contact_messages(status);
create index if not exists properties_status_idx on public.properties(status, created_at desc);
create index if not exists jobs_status_idx on public.jobs(status, created_at desc);
create index if not exists applications_created_idx on public.job_applications(created_at desc);
create index if not exists blog_status_idx on public.blog_posts(status, published_at desc);
create index if not exists tasks_due_idx on public.follow_up_tasks(due_date, status);

alter table public.staff_roles enable row level security;
alter table public.contact_messages enable row level security;
alter table public.properties enable row level security;
alter table public.jobs enable row level security;
alter table public.job_applications enable row level security;
alter table public.blog_posts enable row level security;
alter table public.follow_up_tasks enable row level security;

drop policy if exists staff_read_own_role on public.staff_roles;
create policy staff_read_own_role on public.staff_roles for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists public_insert_contact on public.contact_messages;
create policy public_insert_contact on public.contact_messages for insert to anon, authenticated
  with check (status = 'new' and staff_notes = '');
drop policy if exists staff_manage_contact on public.contact_messages;
create policy staff_manage_contact on public.contact_messages for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

drop policy if exists public_read_properties on public.properties;
create policy public_read_properties on public.properties for select to anon, authenticated using (status = 'published');
drop policy if exists staff_manage_properties on public.properties;
create policy staff_manage_properties on public.properties for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

drop policy if exists public_read_jobs on public.jobs;
create policy public_read_jobs on public.jobs for select to anon, authenticated using (status = 'published');
drop policy if exists staff_manage_jobs on public.jobs;
create policy staff_manage_jobs on public.jobs for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

drop policy if exists public_insert_applications on public.job_applications;
create policy public_insert_applications on public.job_applications for insert to anon, authenticated
  with check (status = 'new' and staff_notes = '' and (job_id is null or exists (select 1 from public.jobs j where j.id = job_id and j.status = 'published')));
drop policy if exists staff_manage_applications on public.job_applications;
create policy staff_manage_applications on public.job_applications for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

drop policy if exists public_read_posts on public.blog_posts;
create policy public_read_posts on public.blog_posts for select to anon, authenticated using (status = 'published');
drop policy if exists staff_manage_posts on public.blog_posts;
create policy staff_manage_posts on public.blog_posts for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

drop policy if exists staff_manage_tasks on public.follow_up_tasks;
create policy staff_manage_tasks on public.follow_up_tasks for all to authenticated
  using (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.staff_roles r where r.user_id = (select auth.uid()) and r.role in ('owner','admin','staff')));

-- Explicit API grants: newly created public tables are not automatically exposed on newer Supabase projects.
grant usage on schema public to anon, authenticated;
grant select on public.properties, public.jobs, public.blog_posts to anon, authenticated;
grant insert (name,email,phone,service,message) on public.contact_messages to anon, authenticated;
grant insert (job_id,candidate_name,email,phone,cover_note) on public.job_applications to anon, authenticated;
grant select on public.staff_roles to authenticated;
grant select, insert, update, delete on public.contact_messages, public.properties, public.jobs,
  public.job_applications, public.blog_posts, public.follow_up_tasks to authenticated;
