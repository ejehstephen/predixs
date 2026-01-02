-- FIXED: Delete Account (Force Cleanup, No Creator ID)
-- Run this in Supabase SQL Editor.

create or replace function delete_own_account()
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  
  -- 1. Detach or Delete Public Data linked to Profile/User ID
  -- We must delete these because they point to your Profile.
  
  delete from public.transactions where user_id = v_user_id;
  delete from public.trades where user_id = v_user_id;
  delete from public.positions where user_id = v_user_id;
  delete from public.kyc_documents where user_id = v_user_id;
  
  -- Admin entry
  delete from public.admins where profile_id = v_user_id;
  
  -- NOTE: We removed the 'markets' update because the 'creator_id' column 
  -- does not exist in your current database schema.
  -- update public.markets set creator_id = null where creator_id = v_user_id;

  -- 2. Delete the user from auth.users
  -- This will now succeed and automatically cascade to delete your 'public.profiles' and 'public.wallets'
  delete from auth.users where id = v_user_id;
end;
$$;
