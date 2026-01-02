-- =================================================================
-- REFUND LOGIC (Append to supabase_withdrawals.sql)
-- =================================================================

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
  -- 1. Get Request Details
  select user_id, amount, status into v_user_id, v_amount, v_status
  from public.withdraw_requests
  where id = p_request_id;

  if not found then
    raise exception 'Request not found';
  end if;

  -- 2. Validate Status (Prevent double refund)
  if v_status = 'failed' or v_status = 'reversed' then
    raise exception 'Already refunded or failed';
  end if;
  
  -- 3. Refund Wallet
  update public.wallets
  set balance = balance + v_amount,
      updated_at = now()
  where user_id = v_user_id;

  -- 4. Log Refund Transaction
  insert into public.transactions (user_id, type, amount, status, metadata)
  values (
    v_user_id,
    'refund',
    v_amount,
    'completed',
    json_build_object('reason', p_reason, 'original_request', p_request_id)
  );

  -- 5. Update Request Status
  update public.withdraw_requests
  set status = 'failed',
      updated_at = now()
  where id = p_request_id;
  
end;
$$;
