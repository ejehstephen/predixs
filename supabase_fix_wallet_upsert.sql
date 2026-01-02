-- Fix: "Self-Healing" Deposit Function + Missing Constraint
-- Run this in Supabase SQL Editor.

-- 1. FIX TABLE SCHEMA
-- The 'wallets' table likely has a plain index on user_id but not a UNIQUE constraint.
-- ON CONFLICT requires a unique constraint/index. We add it here.
alter table public.wallets 
drop constraint if exists wallets_user_id_key;

alter table public.wallets
add constraint wallets_user_id_key unique (user_id);

-- 2. FIX FUNCTION
-- Modified deposit logic to handle missing wallet rows.
create or replace function deposit_funds(p_amount numeric)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  -- Get current user ID securely
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  -- "Upsert" Logic:
  -- Attempt to INSERT a new wallet.
  -- ON CONFLICT (now works because of step 1), simply UPDATE the balance.
  insert into public.wallets (user_id, balance, currency)
  values (v_user_id, p_amount, 'NGN')
  on conflict (user_id) 
  do update set 
    balance = wallets.balance + p_amount,
    updated_at = now();

  -- Create Transaction Record
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'deposit',
    p_amount,
    'completed',
    '{"method": "manual_simulation", "recovered": true}'::jsonb
  );
end;
$$;
