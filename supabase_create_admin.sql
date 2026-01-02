-- PROMOTE USER TO ADMIN
-- Run this in Supabase SQL Editor.

-- Replace 'YOUR_USER_ID_HERE' with your actual User ID from the Authentication table.
-- You can find this ID in the Supabase Dashboard -> Authentication -> Users.

insert into public.admins (profile_id, role)
values (
  'YOUR_USER_ID_HERE', -- <--- PASTE YOUR UUID HERE
  'superadmin'
);

-- Note:
-- If the table 'admins' does not exist, you may need to run the setup script first.
-- This assumes public.admins(id, profile_id, role) exists.
