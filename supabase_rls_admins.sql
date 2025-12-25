-- ==========================================
-- 🛡️ PRODUCTION ADMIN SECURITY & RLS
-- ==========================================

-- 1. Ensure Table Structure is Robust
create table if not exists public.admins (
    id uuid default gen_random_uuid() primary key,
    profile_id uuid references auth.users(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    created_by uuid references auth.users(id), -- Audit who added them
    unique(profile_id) -- One admin entry per user
);

-- 2. Audit Logging Table (Who did what?)
create table if not exists public.admin_audit_logs (
    id uuid default gen_random_uuid() primary key,
    admin_id uuid references auth.users(id),
    action text not null, -- 'create_market', 'resolve_market', 'ban_user'
    target_resource text,
    details jsonb,
    ip_address text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.admins enable row level security;
alter table public.admin_audit_logs enable row level security;

-- ==========================================
-- 🔐 SECURITY POLICIES (RLS)
-- ==========================================

-- Helper Function: Check if current user is admin
-- NOTE: We use SECURITY DEFINER to bypass RLS for this check itself to avoid infinite recursion
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.admins 
    where profile_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- ADMINS TABLE POLICIES

-- 1. Read: Users can see IF they are an admin
--    AND existing admins can see list of all admins.
drop policy if exists "Admin Visibility" on public.admins;
create policy "Admin Visibility" on public.admins
  for select
  using (
    -- You can see yourself
    auth.uid() = profile_id 
    OR 
    -- Admins can see everyone
    public.is_admin()
  );

-- 2. Write: ONLY Service Role (Database Owner) can insert/delete admins.
-- We intentionally DO NOT add insert/update/delete policies for public/auth users.
-- This prevents a compromised admin account from deleting other admins.
-- To add an admin, you MUST use the Supabase Dashboard SQL Editor.

-- AUDIT LOG POLICIES

-- 1. Insert: Admins can insert logs (system automatically does this via triggers usually, but app might too)
drop policy if exists "Admins Log Actions" on public.admin_audit_logs;
create policy "Admins Log Actions" on public.admin_audit_logs
  for insert
  with check (public.is_admin());

-- 2. Read: Only Admins can view audit logs
drop policy if exists "Admins View Logs" on public.admin_audit_logs;
create policy "Admins View Logs" on public.admin_audit_logs
  for select
  using (public.is_admin());

-- ==========================================
-- 🧠 AUTOMATION (Triggers)
-- ==========================================

-- Function to Auto-Log market resolutions
create or replace function log_market_resolution()
returns trigger as $$
begin
  if NEW.is_resolved = true and OLD.is_resolved = false then
    insert into public.admin_audit_logs (admin_id, action, target_resource, details)
    values (
      auth.uid(), 
      'resolve_market', 
      NEW.id::text, 
      json_build_object('outcome', NEW.resolution_outcome, 'title', NEW.title)
    );
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

-- Attach trigger to markets table
drop trigger if exists on_market_resolve on public.markets;
create trigger on_market_resolve
  after update on public.markets
  for each row execute function log_market_resolution();
