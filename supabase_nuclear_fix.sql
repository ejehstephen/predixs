-- NUCLEAR CLEANUP & DEBUG
-- We are dropping ALL possible versions of this function to ensure only ONE exists.

-- 1. Drop Old Version (1 Param)
drop function if exists withdraw_funds(numeric);

-- 2. Drop New Version (4 Params)
drop function if exists withdraw_funds(numeric, text, text, text);

-- 3. Drop Any Other Variants (Best Effort)
-- (Postgres requires types to drop, so we rely on the above covering our cases)

-- 4. Re-Create the LOUD Debug Function
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
  v_new_tx_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  -- 1. Create Transaction (Pending)
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'withdraw_debit',  
    -p_amount,         
    'pending',         
    json_build_object('debug', 'NUCLEAR_TEST')
  ) returning id into v_new_tx_id;

  -- 2. Create Request (Linked) - Just in case we want to see if it works
  insert into public.withdraw_requests (
      user_id, amount, status, bank_name, account_number, account_name, transaction_id
  )
  values (
      v_user_id, p_amount, 'processing', p_bank_name, p_account_number, p_account_name, v_new_tx_id
  );

  -- 3. LOUD DEBUG EXCEPTION
  raise exception 'NUCLEAR DEBUG: ID GENERATED -> %', v_new_tx_id;

end;
$$;
