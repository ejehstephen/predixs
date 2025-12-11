-- Create a trigger function to handle new user signups
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, auth_uid, email, full_name, kyc_level)
  values (
    new.id, -- Force profile ID to match Auth ID
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    0
  );
  
  -- Also create a default wallet for the user
  insert into public.wallets (user_id, currency, balance)
  values (new.id, 'NGN', 0); -- Start with 0 NGN

  return new;
end;
$$;

-- Drop implementation if it exists to avoid duplication errors (optional safety)
drop trigger if exists on_auth_user_created on auth.users;

-- Create the trigger on auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =================================================================
-- BACKFILL: Fix existing users who have no Profile/Wallet
-- (Safe to run multiple times, it skips existing records)
-- =================================================================

-- 1. Create Profiles for existing Auth Users
insert into public.profiles (id, auth_uid, email, full_name, kyc_level)
select
  id,
  id,
  email,
  raw_user_meta_data->>'full_name',
  0
from auth.users
where id not in (select id from public.profiles);

-- 2. Create Wallets for existing Profiles
insert into public.wallets (user_id, currency, balance)
select
  id,
  'NGN',
  0
from public.profiles
where id not in (select user_id from public.wallets);
