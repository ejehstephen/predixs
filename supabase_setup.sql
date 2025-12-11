-- Supabase SQL schema for Predix MVP
-- Run in Supabase SQL editor (Postgres)

-- Enable uuid-ossp for UUID generation (if not already):
create extension if not exists "pgcrypto";

-- USERS (Supabase already has auth, but keep profile)
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  auth_uid uuid references auth.users on delete cascade, -- optional link to Supabase auth
  full_name varchar(200),
  email varchar(200),
  phone varchar(32),
  kyc_level int default 0, -- 0: phone only, 1: verified
  created_at timestamptz default now()
);

-- Wallets (fiat balance ledger)
create table if not exists wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  currency varchar(8) default 'NGN',
  balance numeric(18,2) default 0,
  reserved numeric(18,2) default 0, -- funds reserved for pending orders
  updated_at timestamptz default now()
);

create index if not exists idx_wallets_user on wallets(user_id);

-- Markets
create table if not exists markets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category varchar(64),
  creator_id uuid references profiles(id),
  end_time timestamptz not null,
  status varchar(16) default 'open', -- open/closed/resolved/cancelled
  b_param numeric(18,6) default 1000, -- LMSR liquidity parameter (adjust per market)
  yes_shares numeric(18,6) default 0,
  no_shares numeric(18,6) default 0,
  yes_price numeric(12,6) default 0.5,
  no_price numeric(12,6) default 0.5,
  initial_liquidity numeric(18,6) default 0,
  resolution varchar(8), -- 'yes'|'no'|null
  created_at timestamptz default now()
);

create index if not exists idx_markets_endtime on markets(end_time);
create index if not exists idx_markets_status on markets(status);

-- Trades (history of buys/sells)
create table if not exists trades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  market_id uuid references markets(id),
  side varchar(8) not null, -- 'yes' or 'no'
  amount_paid numeric(18,2) not null, -- NGN
  shares numeric(18,6) not null,
  price_at_trade numeric(12,6) not null, -- price (0-1)
  fee numeric(12,6) default 0,
  created_at timestamptz default now()
);

create index if not exists idx_trades_user on trades(user_id);
create index if not exists idx_trades_market on trades(market_id);

-- Positions (aggregated per user per market)
create table if not exists positions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  market_id uuid references markets(id),
  yes_shares numeric(18,6) default 0,
  no_shares numeric(18,6) default 0,
  average_buy_price numeric(12,6) default 0,
  updated_at timestamptz default now(),
  unique (user_id, market_id)
);

-- Transactions (deposits/withdrawals/payouts)
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  type varchar(32) not null, -- deposit / withdraw_request / withdraw_processed / payout / fee
  amount numeric(18,2) not null,
  currency varchar(8) default 'NGN',
  reference text,
  status varchar(32) default 'pending', -- pending / completed / failed
  metadata jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_transactions_user on transactions(user_id);

-- Admins
create table if not exists admins (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id),
  role varchar(32) default 'moderator',
  created_at timestamptz default now()
);

-- KYC Documents
create table if not exists kyc_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  doc_type varchar(64),
  doc_url text,
  status varchar(32) default 'submitted', -- submitted/approved/rejected
  created_at timestamptz default now()
);

-- Liquidity audit table (track LMSR state changes)
create table if not exists liquidity_events (
  id uuid primary key default gen_random_uuid(),
  market_id uuid references markets(id),
  type varchar(32), -- trade / deposit_liquidity / withdraw_liquidity / resolution
  details jsonb,
  created_at timestamptz default now()
);

-- Useful views
create or replace view market_prices as
select
  id as market_id,
  title,
  (case when yes_shares + no_shares = 0 then 0.5 else yes_shares/(yes_shares+no_shares) end) as implied_prob,
  yes_price,
  no_price
from markets;

-- Row-level security: disable by default while developing, enable and add policies later
-- To enable: ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
