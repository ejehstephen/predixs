-- =================================================================
-- FIX WITHDRAWAL LOGIC V2 (Force Strict Mode)
-- =================================================================

-- 1. DROP the OLD function to prevent any access to the wrong logic
-- This ensures the app MUST use the new one or fail (debugging aid)
drop function if exists withdraw_funds(numeric);

-- 2. Ensure the column definitely exists
do $$
begin
    if not exists (select 1 from information_schema.columns where table_name = 'withdraw_requests' and column_name = 'transaction_id') then
        alter table public.withdraw_requests add column transaction_id uuid references public.transactions(id);
    end if;
end $$;

-- 3. Re-Create the New Function (Robust Version)
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

  -- 1. Deduct Balance Immediately
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- 2. Create Transaction Record (PENDING)
  -- We capture the ID into v_new_tx_id
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'withdraw_debit',  
    -p_amount,         
    'pending',         
    json_build_object(
        'bank_name', p_bank_name,
        'account_number', p_account_number,
        'account_name', p_account_name,
        'method', 'manual_withdrawal'
    )
  ) returning id into v_new_tx_id;

  -- 3. Create Withdrawal Request (LINKED to Transaction)
  insert into public.withdraw_requests (
      user_id, 
      amount, 
      status, 
      bank_name, 
      account_number, 
      account_name, 
      transaction_id -- <--- CRITICAL LINK
  )
  values (
      v_user_id, 
      p_amount, 
      'processing', 
      p_bank_name, 
      p_account_number, 
      p_account_name, 
      v_new_tx_id
  );

end;
$$;
