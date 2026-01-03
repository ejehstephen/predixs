    -- DEBUG RPC: LOUD FAILURE
    -- Run this to verify if this function is actually being called.

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

    -- 1. Create Transaction (Pending)
    insert into public.transactions (user_id, type, amount, status, metadata)
    values (
        v_user_id,
        'withdraw_debit',  
        -p_amount,         
        'pending',         
        json_build_object('debug', 'true')
    ) returning id into v_new_tx_id;

    -- 2. LOUD DEBUG EXCEPTION
    -- This will popup in your Flutter App as a Red Error.
    raise exception 'DEBUG: I AM RUNNING! Tx ID: %', v_new_tx_id;

    end;
    $$;
