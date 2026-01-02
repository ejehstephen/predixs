-- Fix: Allow Admins to insert notifications for other users
-- This fixes the error when marking withdrawals as paid (admin action)

create policy "Admins can insert notifications" on public.notifications
  for insert
  with check (
    -- Allow if the user is an admin
    public.is_admin()
  );
