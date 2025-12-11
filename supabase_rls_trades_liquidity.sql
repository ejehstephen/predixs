-- RLS Policies for Trades and Liquidity Events

-- 1. TRADES
alter table public.trades enable row level security;

-- Users can only view their own trades
drop policy if exists "Users can view own trades" on public.trades;
create policy "Users can view own trades" on public.trades
  for select using (auth.uid() = user_id);

-- No public insert/update allowed for trades (handled by RPCs/System)


-- 2. LIQUIDITY EVENTS
alter table public.liquidity_events enable row level security;

-- Liquidity events are public market data (Auditable)
drop policy if exists "Liquidity events are public" on public.liquidity_events;
create policy "Liquidity events are public" on public.liquidity_events
  for select using (true);

-- No public insert/update allowed (System only)
