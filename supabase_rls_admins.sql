-- RLS Policies for Admins Table

alter table public.admins enable row level security;

-- 1. READ: Users can check if THEY are an admin
-- This allows the app to query: select * from admins where profile_id = my_id
drop policy if exists "Users can check own admin status" on public.admins;
create policy "Users can check own admin status" on public.admins
  for select using (auth.uid() = profile_id);

-- 2. WRITE: Only Service Role (Database Admin) can add/remove admins
-- No public insert/update/delete policies are created.
-- This means you must add new admins manually via Supabase Dashboard or SQL Query.
