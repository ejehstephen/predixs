-- =================================================================
-- PRODUCTION TRIGGER MIGRATION
-- Run this in your production Supabase SQL Editor.
-- =================================================================

-- 1. Create the function that will handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  -- Create a Public Profile for the new User
  insert into public.profiles (id, auth_uid, email, full_name, kyc_level)
  values (
    new.id, -- Force profile ID to match Auth ID
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    0
  );
  
  -- Create a Default Wallet for the new User
  insert into public.wallets (user_id, currency, balance)
  values (new.id, 'NGN', 0);

  return new;
end;
$$;

-- 2. Clean up previous triggers to avoid conflicts
drop trigger if exists on_auth_user_created on auth.users;

-- 3. Attach the Trigger to the Auth table
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
