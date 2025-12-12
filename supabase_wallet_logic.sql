-- =================================================================
-- WALLET TRANSACTION LOGIC
-- Run this in Supabase SQL Editor to enable Deposit/Withdraw
-- =================================================================

-- 1. Deposit Funds (RPC)
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

  -- 1. Update Wallet Balance
  update public.wallets
  set balance = balance + p_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- 2. Create Transaction Record
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'deposit',
    p_amount,
    'completed',
    '{"method": "manual_simulation"}'::jsonb
  );
end;
$$;

-- 2. Withdraw Funds (RPC)
create or replace function withdraw_funds(p_amount numeric)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_current_balance numeric;
  v_fee numeric;
  v_net_amount numeric;
begin
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;

  -- Fee Calculation (1.5%)
  v_fee := p_amount * 0.015;
  v_net_amount := p_amount - v_fee; 
  -- Note: We assume p_amount is what they want to take out of their wallet total.
  -- e.g. Withdraw 100 -> Wallet -100, User receives 98.5, Platform keeps 1.5.

  -- Check balance
  select balance into v_current_balance
  from public.wallets
  where user_id = v_user_id;

  if v_current_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  -- 1. Deduct Balance (Full Amount)
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- 2. Create Transaction Records
  -- A. The Withdrawal
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'withdraw_request',
    v_net_amount, -- Log the amount they actually get
    'completed',
    json_build_object('fee', v_fee, 'gross_amount', p_amount)
  );

  -- B. The Fee Log (Optional, but good for admin)
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'fee',
    v_fee,
    'completed',
    json_build_object('source', 'withdrawal', 'ref_amount', p_amount)
  );

end;
$$;
