-- Drop existing tables to ensure clean schema (Dev only)
drop table if exists public.positions cascade;
drop table if exists public.markets cascade;

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
  yes_price numeric default 0.5,
  no_price numeric default 0.5,
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
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on positions
alter table public.positions enable row level security;

-- Allow users to view their own positions
drop policy if exists "Users can view own positions" on public.positions;
create policy "Users can view own positions" on public.positions
  for select using (auth.uid() = user_id);

-- RPC: Buy Shares
drop function if exists buy_shares(uuid, text, numeric);

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
  v_shares numeric;
  v_existing_position_id uuid;
  v_new_avg_price numeric;
  v_new_shares numeric;
  v_total_invested numeric;
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

  -- 1. Check Wallet Balance
  select id, balance into v_wallet_id, v_balance
  from public.wallets
  where user_id = v_user_id;

  if v_wallet_id is null then
    raise exception 'Wallet not found';
  end if;

  if v_balance < p_amount then
    raise exception 'Insufficient funds';
  end if;

  -- 2. Get Market Price
  if p_outcome = 'Yes' then
    select yes_price into v_market_price from public.markets where id = p_market_id;
  elsif p_outcome = 'No' then
    select no_price into v_market_price from public.markets where id = p_market_id;
  else
    raise exception 'Invalid outcome';
  end if;

  if v_market_price is null then
    raise exception 'Market not found';
  end if;

  -- Calculate shares (Simple Fixed Price Model for now)
  v_shares := p_amount / v_market_price;

  -- 3. Deduct from Wallet
  update public.wallets
  set balance = balance - p_amount,
      updated_at = now()
  where id = v_wallet_id;

  -- 4. Record Transaction
  insert into public.transactions (wallet_id, type, amount, status)
  values (v_wallet_id, 'buy', -p_amount, 'completed');

  -- 5. Update/Create Position
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

  -- 6. Update Market Volume
  update public.markets
  set volume = volume + p_amount
  where id = p_market_id;

  return json_build_object(
    'success', true,
    'shares', v_shares,
    'price', v_market_price
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
