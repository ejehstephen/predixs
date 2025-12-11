-- Drop existing tables/functions to ensure clean schema
drop table if exists public.positions cascade;
drop table if exists public.markets cascade;
drop function if exists buy_shares(uuid, text, numeric);
drop function if exists sell_shares(uuid, text, numeric);

-- Create markets table
create table public.markets (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  category text not null, -- 'Sports', 'Crypto', 'Politics'
  image_url text,
  end_date timestamp with time zone not null,
  is_resolved boolean default false,
  resolution_outcome text, -- 'Yes', 'No'
  yes_price numeric default 0.5 check (yes_price > 0 and yes_price < 1),
  no_price numeric default 0.5 check (no_price > 0 and no_price < 1),
  volume numeric default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on markets
alter table public.markets enable row level security;

-- Allow public read access to markets
create policy "Markets are viewable by everyone" on public.markets
  for select using (true);

-- Create positions table
create table if not exists public.positions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  market_id uuid references public.markets(id) not null,
  side text not null check (side in ('Yes', 'No')),
  shares numeric not null default 0,
  avg_price numeric not null,
  invested numeric not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, market_id, side) -- Prevent duplicate rows for same position
);

-- Enable RLS on positions
alter table public.positions enable row level security;

-- Allow users to view their own positions
drop policy if exists "Users can view own positions" on public.positions;
create policy "Users can view own positions" on public.positions
  for select using (auth.uid() = user_id);

-- RPC: Buy Shares (with Price Impact)
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
  v_market_price numeric;
  v_other_price numeric;
  v_shares numeric;
  v_existing_position_id uuid;
  v_new_avg_price numeric;
  v_new_shares numeric;
  v_total_invested numeric;
  v_impact numeric;
begin
  -- Input validation
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  -- Get user ID
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 1. Check Wallet Balance & Lock Row
  select id, balance into v_wallet_id, v_balance
  from public.wallets
  where user_id = v_user_id
  for update; -- Lock wallet to prevent race conditions

  if v_wallet_id is null then
    raise exception 'Wallet not found';
  end if;

  if v_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  -- 2. Get Market Price & Lock Row
  -- We select both prices to update them
  select yes_price, no_price into v_market_price, v_other_price
  from public.markets
  where id = p_market_id
  for update;

  if v_market_price is null then
    raise exception 'Market not found';
  end if;

  -- Determine price based on outcome
  if p_outcome = 'Yes' then
    v_market_price := v_market_price; -- current yes_price
    -- Impact: Price goes UP. 0.001 per $1.
    -- Example: Buy $10 -> Price + 0.01
    v_impact := p_amount * 0.001;
  elsif p_outcome = 'No' then
    v_market_price := v_other_price; -- current no_price
    v_impact := p_amount * 0.001;
  else
    raise exception 'Invalid outcome';
  end if;

  -- 3. Calculate Shares (at current pre-impact price)
  v_shares := p_amount / v_market_price;

  -- 4. Apply Price Impact (Linear Model)
  v_market_price := v_market_price + v_impact;
  
  -- Clamp price to [0.01, 0.99]
  if v_market_price > 0.99 then v_market_price := 0.99; end if;
  
  -- The other side moves opposite (1 - price)
  v_other_price := 1.0 - v_market_price;
  
  if v_other_price < 0.01 then 
     v_other_price := 0.01;
     v_market_price := 0.99;
  end if;

  -- Update Market Prices
  if p_outcome = 'Yes' then
    update public.markets
    set yes_price = v_market_price,
        no_price = v_other_price,
        volume = volume + p_amount
    where id = p_market_id;
  else
    update public.markets
    set yes_price = v_other_price,
        no_price = v_market_price,
        volume = volume + p_amount
    where id = p_market_id;
  end if;

  -- 5. Deduct from Wallet
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where id = v_wallet_id;

  -- 6. Record Transaction
  insert into public.transactions (user_id, type, amount, status)
  values (v_user_id, 'buy', -p_amount, 'completed');

  -- 7. Update/Create Position
  select id, shares, invested into v_existing_position_id, v_new_shares, v_total_invested
  from public.positions
  where user_id = v_user_id and market_id = p_market_id and side = p_outcome;

  if v_existing_position_id is not null then
    -- Update existing position
    v_new_shares := v_new_shares + v_shares;
    v_total_invested := v_total_invested + p_amount;
    v_new_avg_price := v_total_invested / v_new_shares;

    update public.positions
    set shares = v_new_shares,
        invested = v_total_invested,
        avg_price = v_new_avg_price
    where id = v_existing_position_id;
  else
    -- Create new position
    insert into public.positions (user_id, market_id, side, shares, avg_price, invested)
    values (v_user_id, p_market_id, p_outcome, v_shares, v_market_price, p_amount);
  end if;

  return json_build_object(
    'success', true,
    'shares', v_shares,
    'price', v_market_price
  );
end;
$$;

-- RPC: Sell Shares (New)
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
  v_current_price numeric;
  v_other_price numeric;
  v_existing_position_id uuid;
  v_current_shares numeric;
  v_return_amount numeric;
  v_impact numeric;
  v_pnl numeric;
begin
  if p_shares_to_sell <= 0 then
    raise exception 'Shares must be positive';
  end if;

  v_user_id := auth.uid();
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  -- 1. Verify Ownership
  select id, shares into v_existing_position_id, v_current_shares
  from public.positions
  where user_id = v_user_id and market_id = p_market_id and side = p_outcome;

  if v_existing_position_id is null or v_current_shares < p_shares_to_sell then
    raise exception 'Insufficient shares';
  end if;

  -- 2. Get Market Price & Lock
  select yes_price, no_price into v_current_price, v_other_price
  from public.markets
  where id = p_market_id
  for update;

  if p_outcome = 'Yes' then
    v_current_price := v_current_price;
  else 
    v_current_price := v_other_price; -- Selling 'No' shares uses No Price
  end if;

  -- 3. Calculate Return Logic
  -- Return = Shares * Price
  v_return_amount := p_shares_to_sell * v_current_price;

  -- 4. Apply Price Impact (Selling lowers price)
  -- Impact works same way: Return Amount * 0.001
  v_impact := v_return_amount * 0.001;
  v_current_price := v_current_price - v_impact;

  -- Clamp
  if v_current_price < 0.01 then v_current_price := 0.01; end if;
  v_other_price := 1.0 - v_current_price;

  -- Update Market
  if p_outcome = 'Yes' then
    update public.markets
    set yes_price = v_current_price, no_price = v_other_price
    where id = p_market_id;
  else
    update public.markets
    set yes_price = v_other_price, no_price = v_current_price
    where id = p_market_id;
  end if;

  -- 5. Update Wallet
  select id into v_wallet_id from public.wallets where user_id = v_user_id;
  
  update public.wallets
  set balance = balance + v_return_amount,
      updated_at = now()
  where id = v_wallet_id;

  -- 6. Update Position
  if v_current_shares = p_shares_to_sell then
    -- Sold everything
    delete from public.positions where id = v_existing_position_id;
  else
    update public.positions
    set shares = shares - p_shares_to_sell,
        invested = (shares - p_shares_to_sell) * (select avg_price from public.positions where id = v_existing_position_id) -- Reduce invested proportionally
    where id = v_existing_position_id;
  end if;

  -- 7. Record Transaction
  insert into public.transactions (user_id, type, amount, status)
  values (v_user_id, 'sell', v_return_amount, 'completed');

  return json_build_object(
    'success', true,
    'returnAmount', v_return_amount,
    'newPrice', v_current_price
  );
end;
$$;


-- Seed Data (Dummy Markets)
insert into public.markets (title, category, end_date, yes_price, no_price, image_url)
select * from (values
  ('Will BTC hit $100k in 2024?', 'Crypto', now() + interval '30 days', 0.65, 0.35, 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?auto=format&fit=crop&q=80&w=500'),
  ('Will Man City win the Premier League?', 'Sports', now() + interval '14 days', 0.45, 0.55, 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=500'),
  ('Will GPT-5 be released before Q3?', 'Tech', now() + interval '90 days', 0.20, 0.80, 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&q=80&w=500')
) as v(title, category, end_date, yes_price, no_price, image_url)
where not exists (
  select 1 from public.markets where title = v.title
);
