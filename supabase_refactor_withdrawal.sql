-- =================================================================
-- REFACTOR WITHDRAWAL LOGIC (User Request: Single Transaction Logic)
-- =================================================================

-- 1. Add transaction_id to withdraw_requests table
-- We use do block to avoid error if column exists
do $$
begin
    if not exists (select 1 from information_schema.columns where table_name = 'withdraw_requests' and column_name = 'transaction_id') then
        alter table public.withdraw_requests add column transaction_id uuid references public.transactions(id);
    end if;
end $$;

-- 2. Update withdraw_funds RPC to handle Bank Details and Link Transaction
create or replace function withdraw_funds(
    p_amount numeric,
    p_bank_name text default 'Unknown',
    p_account_number text default 'Unknown',
    p_account_name text default 'Unknown'
)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_current_balance numeric;
  v_new_tx_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;

  -- Check balance
  select balance into v_current_balance
  from public.wallets
  where user_id = v_user_id;

  if v_current_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  -- 1. Deduct Balance Immediately (Lock verification funds)
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- 2. Create Transaction Record (PENDING)
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'withdraw_debit',  -- Using consistent type
    -p_amount,         -- Negative amount for withdrawal
    'pending',         -- Status is pending until Admin approves
    json_build_object(
        'bank_name', p_bank_name,
        'account_number', p_account_number,
        'method', 'manual_withdrawal'
    )
  ) returning id into v_new_tx_id;

  -- 3. Create Withdrawal Request (Linked to Transaction)
  insert into public.withdraw_requests (
      user_id, 
      amount, 
      status, 
      bank_name, 
      account_number, 
      account_name, 
      transaction_id
  )
  values (
      v_user_id, 
      p_amount, 
      'processing', -- pending admin review
      p_bank_name, 
      p_account_number, 
      p_account_name, 
      v_new_tx_id
  );

end;
$$;
