-- 1. Fix Missing Column
ALTER TABLE markets ADD COLUMN IF NOT EXISTS volume numeric(18,6) DEFAULT 0;

-- 2. Create "Buy Shares" Function (The Core Engine)
-- This function handles the money, the shares, and the price update atomically.
CREATE OR REPLACE FUNCTION buy_shares(
  p_market_id uuid,
  p_outcome text, -- 'yes' or 'no'
  p_amount numeric  -- Amount in NGN
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_market markets%ROWTYPE;
  v_shares_out numeric;
  v_new_pool_yes numeric;
  v_new_pool_no numeric;
  v_prob numeric;
BEGIN
  v_user_id := auth.uid();
  
  -- 1. Get Market Info
  SELECT * INTO v_market FROM markets WHERE id = p_market_id;
  
  IF v_market.status != 'open' THEN
    RAISE EXCEPTION 'Market is closed';
  END IF;

  -- 2. Deduct Money from Wallet (Simple Check)
  UPDATE wallets 
  SET balance = balance - p_amount 
  WHERE user_id = v_user_id AND balance >= p_amount;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- 3. Calculate Shares (Simplified CPMM/LMSR Logic)
  -- For MVP, we presume price = probability. 
  -- shares = amount / price. 
  -- In a real AMM, this moves the price. We will implement simple price moving here.
  
  IF p_outcome = 'yes' THEN
    -- Buy YES: Price goes UP.
    -- Simple Linear Price Impact for MVP: Price moves by 0.001 per 1000 NGN
    v_shares_out := p_amount / v_market.yes_price;
    v_new_pool_yes := v_market.yes_shares + v_shares_out;
    
    -- Update Market State
    UPDATE markets
    SET 
      yes_shares = yes_shares + v_shares_out,
      volume = volume + p_amount,
      -- Price Impact Logic (Simplified):
      yes_price = LEAST(0.99, yes_price + (p_amount / 100000)), 
      no_price = GREATEST(0.01, 1.0 - (LEAST(0.99, yes_price + (p_amount / 100000))))
    WHERE id = p_market_id;

  ELSE
    -- Buy NO
    v_shares_out := p_amount / v_market.no_price;
    v_new_pool_no := v_market.no_shares + v_shares_out;
    
    -- Update Market State
    UPDATE markets
    SET 
      no_shares = no_shares + v_shares_out,
      volume = volume + p_amount,
      no_price = LEAST(0.99, no_price + (p_amount / 100000)),
      yes_price = GREATEST(0.01, 1.0 - (LEAST(0.99, no_price + (p_amount / 100000))))
    WHERE id = p_market_id;
  END IF;

  -- 4. Record the Trade
  INSERT INTO trades (user_id, market_id, side, amount_paid, shares, price_at_trade)
  VALUES (v_user_id, p_market_id, p_outcome, p_amount, v_shares_out, 
    CASE WHEN p_outcome = 'yes' THEN v_market.yes_price ELSE v_market.no_price END
  );

  -- 5. Update/Create User Position
  INSERT INTO positions (user_id, market_id, yes_shares, no_shares)
  VALUES (
    v_user_id, 
    p_market_id, 
    CASE WHEN p_outcome = 'yes' THEN v_shares_out ELSE 0 END,
    CASE WHEN p_outcome = 'no' THEN v_shares_out ELSE 0 END
  )
  ON CONFLICT (user_id, market_id) DO UPDATE
  SET 
    yes_shares = positions.yes_shares + EXCLUDED.yes_shares,
    no_shares = positions.no_shares + EXCLUDED.no_shares,
    updated_at = now();

  RETURN jsonb_build_object('success', true, 'shares', v_shares_out);
END;
$$;
