-- Drop tables to reset schema for LMSR
drop table if exists public.positions cascade;
drop table if exists public.markets cascade;

-- Create markets table (LMSR Version)
create table public.markets (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  category text not null,
  image_url text,
  end_date timestamp with time zone not null,
  is_resolved boolean default false,
  resolution_outcome text, -- 'Yes', 'No'
  
  -- LMSR State
  -- b: Liquidity parameter. Higher b = less price movement per trade.
  liquidity_b numeric not null default 100.0, 
  -- Total shares outstanding. These track the 'state' of the market.
  yes_shares numeric not null default 0,
  no_shares numeric not null default 0,
  
  -- Cached display prices (Computed from shares, but stored for easy sorting/display)
  yes_price numeric not null default 0.5,
  no_price numeric not null default 0.5,
  
  volume numeric default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.markets enable row level security;
create policy "Markets are public" on public.markets for select using (true);

-- Create positions table
create table public.positions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  market_id uuid references public.markets(id) not null,
  side text not null check (side in ('Yes', 'No')),
  shares numeric not null default 0,
  avg_price numeric not null,
  invested numeric not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, market_id, side)
);

-- Enable RLS
alter table public.positions enable row level security;
create policy "Users view own positions" on public.positions for select using (auth.uid() = user_id);

-- LMSR Cost Function (Helper)
-- Robust implementation using Log-Sum-Exp trick to prevent overflow
-- C = b * ln(exp(q1/b) + exp(q2/b))
-- Rewritten: C = b * (M + ln(exp(q1/b - M) + exp(q2/b - M))) where M = max(q1/b, q2/b)
create or replace function calculate_lmsr_cost(
  p_yes_shares numeric,
  p_no_shares numeric,
  p_b numeric
) returns numeric
language plpgsql
immutable
as $$
declare
  v_x numeric;
  v_y numeric;
  v_max numeric;
begin
  v_x := p_yes_shares / p_b;
  v_y := p_no_shares / p_b;
  
  -- Find Max to normalize
  if v_x > v_y then
    v_max := v_x;
  else
    v_max := v_y;
  end if;
  
  -- Result is scaled back by b
  return p_b * (v_max + ln(exp(v_x - v_max) + exp(v_y - v_max)));
end;
$$;


-- RPC: Buy Shares (LMSR)
create or replace function buy_shares(
  p_market_id uuid,
  p_outcome text,
  p_amount numeric
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_wallet_id uuid;
  v_balance numeric;
  
  v_b numeric;
  v_q_yes numeric;
  v_q_no numeric;
  v_cost_old numeric;
  v_cost_new numeric;
  v_new_q_yes numeric;
  v_new_q_no numeric;
  v_shares_bought numeric;
  v_price_per_share numeric;
  
  v_new_limit_price_yes numeric;
  v_new_limit_price_no numeric;
  v_exp_yes numeric;
  v_exp_no numeric;
  v_max_exp numeric;
  
  v_existing_pos_id uuid;
  v_pos_shares numeric;
  v_pos_invested numeric;
begin
  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;
  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  -- 1. Lock Wallet & Check Balance
  select id, balance into v_wallet_id, v_balance from public.wallets where user_id = v_user_id for update;
  if v_balance < p_amount then raise exception 'Insufficient funds'; end if;

  -- 2. Lock Market & Get State
  select liquidity_b, yes_shares, no_shares into v_b, v_q_yes, v_q_no
  from public.markets where id = p_market_id for update;
  if v_b is null then raise exception 'Market not found'; end if;

  -- 3. Calculate LMSR Logic
  -- Cost_New = Cost_Old + Amount
  v_cost_old := calculate_lmsr_cost(v_q_yes, v_q_no, v_b);
  v_cost_new := v_cost_old + p_amount;
  
  -- Solve for new shares count using Stable Inverse
  -- Formula: q_new = C_new + b * ln(1 - exp((q_other - C_new)/b))
  
  if p_outcome = 'Yes' then
    v_new_q_no := v_q_no;
    
    -- Check for math domain validity (liquidity constraint)
    -- Term inside log must be > 0: (1 - exp(...)) > 0  => exp(...) < 1 => (q_other - C_new) < 0 => q_other < C_new
    if v_cost_new <= v_q_no then
       raise exception 'Math Overlap: Liquidity too low for this trade size'; 
    end if;
    
    v_new_q_yes := v_cost_new + v_b * ln(1.0 - exp((v_q_no - v_cost_new)/v_b));
    v_shares_bought := v_new_q_yes - v_q_yes;
    
  else -- Buying NO
    v_new_q_yes := v_q_yes;
    
    if v_cost_new <= v_q_yes then
       raise exception 'Math Overlap: Liquidity too low for this trade size'; 
    end if;
    
    v_new_q_no := v_cost_new + v_b * ln(1.0 - exp((v_q_yes - v_cost_new)/v_b));
    v_shares_bought := v_new_q_no - v_q_no;
  end if;
  
  if v_shares_bought <= 0 then raise exception 'Trade resulted in zero shares'; end if;

  v_price_per_share := p_amount / v_shares_bought;

  -- 4. Update Market State
  -- Calculate new instantaneous prices (Robust)
  -- P_yes = exp(yes/b - max) / (exp(yes/b - max) + exp(no/b - max))
  
  if (v_new_q_yes/v_b) > (v_new_q_no/v_b) then
     v_max_exp := v_new_q_yes/v_b;
  else
     v_max_exp := v_new_q_no/v_b;
  end if;
  
  v_exp_yes := exp((v_new_q_yes/v_b) - v_max_exp);
  v_exp_no := exp((v_new_q_no/v_b) - v_max_exp);
  
  v_new_limit_price_yes := v_exp_yes / (v_exp_yes + v_exp_no);
  v_new_limit_price_no := v_exp_no / (v_exp_yes + v_exp_no);

  update public.markets
  set yes_shares = v_new_q_yes,
      no_shares = v_new_q_no,
      yes_price = v_new_limit_price_yes,
      no_price = v_new_limit_price_no,
      volume = volume + p_amount
  where id = p_market_id;

  -- 5. Deduct Wallet
  update public.wallets set balance = balance - p_amount, updated_at = now() where id = v_wallet_id;
  insert into public.transactions (user_id, type, amount, status) values (v_user_id, 'buy', -p_amount, 'completed');

  -- 6. Update Position
  select id, shares, invested into v_existing_pos_id, v_pos_shares, v_pos_invested
  from public.positions where user_id = v_user_id and market_id = p_market_id and side = p_outcome;
  
  if v_existing_pos_id is not null then
    update public.positions
    set shares = shares + v_shares_bought,
        invested = invested + p_amount,
        avg_price = (invested + p_amount) / (shares + v_shares_bought)
    where id = v_existing_pos_id;
  else
    insert into public.positions (user_id, market_id, side, shares, invested, avg_price)
    values (v_user_id, p_market_id, p_outcome, v_shares_bought, p_amount, v_price_per_share);
  end if;

  return json_build_object('success', true, 'shares', v_shares_bought, 'price', v_price_per_share);
end;
$$;


-- RPC: Sell Shares (LMSR)
create or replace function sell_shares(
  p_market_id uuid,
  p_outcome text,
  p_shares_to_sell numeric
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_wallet_id uuid;
  
  v_b numeric;
  v_q_yes numeric;
  v_q_no numeric;
  v_cost_old numeric;
  v_cost_new numeric;
  v_new_q_yes numeric;
  v_new_q_no numeric;
  v_return_amount numeric;
  
  v_new_limit_price_yes numeric;
  v_new_limit_price_no numeric;
  v_exp_yes numeric;
  v_exp_no numeric;
  v_max_exp numeric;
  
  v_existing_pos_id uuid;
  v_pos_shares numeric;
begin
  if p_shares_to_sell <= 0 then raise exception 'Shares must be positive'; end if;
  v_user_id := auth.uid();

  -- Verify Ownership
  select id, shares into v_existing_pos_id, v_pos_shares from public.positions
  where user_id = v_user_id and market_id = p_market_id and side = p_outcome;
  
  if v_existing_pos_id is null or v_pos_shares < p_shares_to_sell then
    raise exception 'Insufficient shares';
  end if;

  -- Lock Market
  select liquidity_b, yes_shares, no_shares into v_b, v_q_yes, v_q_no
  from public.markets where id = p_market_id for update;

  -- LMSR Sell Logic
  v_cost_old := calculate_lmsr_cost(v_q_yes, v_q_no, v_b);
  
  if p_outcome = 'Yes' then
    v_new_q_yes := v_q_yes - p_shares_to_sell;
    v_new_q_no := v_q_no;
  else
    v_new_q_yes := v_q_yes;
    v_new_q_no := v_q_no - p_shares_to_sell;
  end if;
  
  v_cost_new := calculate_lmsr_cost(v_new_q_yes, v_new_q_no, v_b);
  v_return_amount := v_cost_old - v_cost_new;

  -- Update Market Prices (Robust)
  if (v_new_q_yes/v_b) > (v_new_q_no/v_b) then
     v_max_exp := v_new_q_yes/v_b;
  else
     v_max_exp := v_new_q_no/v_b;
  end if;

  v_exp_yes := exp((v_new_q_yes/v_b) - v_max_exp);
  v_exp_no := exp((v_new_q_no/v_b) - v_max_exp);
  v_new_limit_price_yes := v_exp_yes / (v_exp_yes + v_exp_no);
  v_new_limit_price_no := v_exp_no / (v_exp_yes + v_exp_no);

  update public.markets
  set yes_shares = v_new_q_yes,
      no_shares = v_new_q_no,
      yes_price = v_new_limit_price_yes,
      no_price = v_new_limit_price_no
  where id = p_market_id;

  -- Update Wallet
  select id into v_wallet_id from public.wallets where user_id = v_user_id;
  update public.wallets set balance = balance + v_return_amount, updated_at = now() where id = v_wallet_id;
  insert into public.transactions (user_id, type, amount, status) values (v_user_id, 'sell', v_return_amount, 'completed');

  -- Update Position
  if v_pos_shares = p_shares_to_sell then
    delete from public.positions where id = v_existing_pos_id;
  else
    update public.positions
    set shares = shares - p_shares_to_sell,
        invested = invested * ((shares - p_shares_to_sell) / shares)
    where id = v_existing_pos_id;
  end if;

  return json_build_object('success', true, 'returnAmount', v_return_amount, 'newPrice', v_new_limit_price_yes);
end;
$$;

-- Seed Data (LMSR uses shares to set price)
-- b=100. To get price 0.5, shares can be 0,0.
insert into public.markets (title, category, end_date, yes_price, no_price, image_url, liquidity_b, yes_shares, no_shares)
select * from (values
  ('Will BTC hit $100k in 2024?', 'Crypto', now() + interval '30 days', 0.5, 0.5, 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?auto=format&fit=crop&q=80&w=500', 100.0, 0, 0),
  ('Will Man City win the Premier League?', 'Sports', now() + interval '14 days', 0.5, 0.5, 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=500', 100.0, 0, 0),
  ('Will GPT-5 be released before Q3?', 'Tech', now() + interval '90 days', 0.5, 0.5, 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&q=80&w=500', 100.0, 0, 0)
) as v(a,b,c,d,e,f,g,h,i);
