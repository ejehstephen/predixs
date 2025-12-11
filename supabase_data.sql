-- Insert Dummy Markets for Testing
-- Run this in Supabase SQL Editor

INSERT INTO public.markets (
  title, 
  category, 
  end_time, 
  yes_price, 
  no_price, 
  volume, 
  initial_liquidity,
  status,
  description
)
VALUES 
  (
    'Will Bitcoin hit $100k by 2024?', 
    'Crypto', 
    now() + interval '30 days', 
    0.65, 
    0.35, 
    125000, 
    10000,
    'open',
    'Binary prediction market for Bitcoin price performance in 2024.'
  ),
  (
    'Man City to win Premier League 23/24?', 
    'Sports', 
    now() + interval '90 days', 
    0.80, 
    0.20, 
    540000, 
    50000,
    'open',
    'Market for English Premier League winner.'
  ),
  (
    'Will Nigeria GDP grow > 3% in Q4?', 
    'Economy', 
    now() + interval '20 days', 
    0.45, 
    0.55, 
    85000, 
    20000,
    'open',
    'Economic indicator prediction.'
  ),
  (
    'Davido to win a Grammy in 2024?', 
    'Pop Culture', 
    now() + interval '120 days', 
    0.30, 
    0.70, 
    210000, 
    15000,
    'open',
    'Music awards prediction.'
  );
