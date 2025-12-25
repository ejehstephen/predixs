-- Add is_banned column to profiles
alter table public.profiles 
add column if not exists is_banned boolean default false;

-- Allow Admins to update profiles (to ban/unban)
create policy "Admins can update any profile"
on public.profiles
for update
using (
  exists (
    select 1 from public.admins
    where id = auth.uid()
  )
);
