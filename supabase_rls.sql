-- Predixs Master RLS Script
-- Run this to secure all tables in the application.

-- 1. PROFILES
alter table public.profiles enable row level security;

drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
create policy "Public profiles are viewable by everyone" on public.profiles
  for select using (true);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- 2. WALLETS
alter table public.wallets enable row level security;

drop policy if exists "Users can view own wallet" on public.wallets;
create policy "Users can view own wallet" on public.wallets
  for select using (auth.uid() = user_id);

-- No update policy for wallets: mutations must happen via secure RPC (buy_shares)
-- or Service Role (deposit/withdraw webhooks).

-- 3. TRANSACTIONS
alter table public.transactions enable row level security;

drop policy if exists "Users can view own transactions" on public.transactions;
create policy "Users can view own transactions" on public.transactions
  for select using (auth.uid() = user_id);

-- 4. NOTIFICATIONS
alter table public.notifications enable row level security;

drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications" on public.notifications
  for select using (auth.uid() = user_id);

drop policy if exists "Users can mark notifications as read" on public.notifications;
create policy "Users can mark notifications as read" on public.notifications
  for update using (auth.uid() = user_id);

-- 5. MARKETS
alter table public.markets enable row level security;

drop policy if exists "Markets are viewable by everyone" on public.markets;
create policy "Markets are viewable by everyone" on public.markets
  for select using (true);

-- 6. POSITIONS
alter table public.positions enable row level security;

drop policy if exists "Users can view own positions" on public.positions;
create policy "Users can view own positions" on public.positions
  for select using (auth.uid() = user_id);

-- 7. KYC DOCUMENTS
alter table public.kyc_documents enable row level security;

drop policy if exists "Users can view own kyc" on public.kyc_documents;
create policy "Users can view own kyc" on public.kyc_documents
  for select using (auth.uid() = user_id);

drop policy if exists "Users can upload kyc" on public.kyc_documents;
create policy "Users can upload kyc" on public.kyc_documents
  for insert with check (auth.uid() = user_id);
