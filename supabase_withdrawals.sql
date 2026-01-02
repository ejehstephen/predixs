-- =================================================================
-- AUTOMATED WITHDRAWAL SCHEMA
-- =================================================================

-- 1. Table to track withdrawal requests (linked to Paystack transfers)
create table if not exists withdraw_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) not null,
  amount numeric(18,2) not null,
  bank_code text,
  bank_name text,
  account_number text,
  account_name text,
  recipient_code text, -- Paystack Recipient Code
  transfer_code text, -- Paystack Transfer Code
  reference text,
  status text default 'processing', -- processing, success, failed, reversed
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Index for querying user history
create index if not exists idx_withdraw_requests_user on withdraw_requests(user_id);

-- 2. Secure RPC to Lock Funds & Check KYC
create or replace function lock_funds_for_withdrawal(p_amount numeric)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_is_verified boolean;
  v_balance numeric;
  v_request_id uuid;
  v_transaction_id uuid;
begin
  -- A. Get User ID
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- B. KYC Check
  select nin_verified into v_is_verified
  from public.profiles
  where id = v_user_id;

  if v_is_verified is not true then
    -- RAISE EXCEPTION 'KYC_REQUIRED'; -- Frontend can catch this string
     -- Or better, return a structured error? 
     -- Raising exception is standard for RPC failures (rolls back everything).
     raise exception 'KYC Verification Required: Please verify your identity (NIN) first.';
  end if;

  -- C. Amount Validation
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;
  
  if p_amount < 100 then -- Minimum withdrawal assumption
    raise exception 'Minimum withdrawal is 100';
  end if;

  -- D. Balance Check
  select balance into v_balance
  from public.wallets
  where user_id = v_user_id
  for update; -- Lock the row to prevent race conditions

  if v_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  -- E. Deduct Balance
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- F. Create Transaction Record (Debit)
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'withdraw_debit',
    p_amount,
    'processing', -- pending final confirmation
    json_build_object('method', 'paystack_transfer')
  )
  returning id into v_transaction_id;

  -- G. Create Request Record (Placeholder, will be updated by Edge Function with bank details)
  insert into public.withdraw_requests (user_id, amount, status)
  values (v_user_id, p_amount, 'pending_details')
  returning id into v_request_id;

  return json_build_object(
    'success', true, 
    'request_id', v_request_id,
    'transaction_id', v_transaction_id,
    'new_balance', v_balance - p_amount
  );
end;
$$;

-- 3. RPC to Refund Failed Withdrawals (Auto-Recovery)
create or replace function refund_failed_withdrawal(p_request_id uuid, p_reason text)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_amount numeric;
  v_status text;
begin
  -- A. Validate Request State
  select user_id, amount, status into v_user_id, v_amount, v_status
  from public.withdraw_requests
  where id = p_request_id;

  if v_status != 'pending_details' then
     -- Already processed or failed, do nothing to avoid double refund
     return;
  end if;

  -- B. Refund Balance
  update public.wallets
  set balance = balance + v_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- C. Update Request Status
  update public.withdraw_requests
  set status = 'failed',
      transfer_code = 'REFUNDED', -- Mark as refunded
      reference = p_reason -- Store error reason here
  where id = p_request_id;

  -- D. Create Refund Transaction
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'refund', -- or 'withdraw_refund'
    v_amount,
    'completed',
    json_build_object('reason', p_reason, 'original_request_id', p_request_id)
  );
  
  -- E. Mark Original Debit as Failed (Optional but good for clarity)
  update public.transactions
  set status = 'failed'
  where user_id = v_user_id 
    and type = 'withdraw_debit' 
    and status = 'processing'
    and created_at > (now() - interval '5 minutes'); -- Heuristic to find the recent debit

end;
$$;
