-- Seed Real World Markets
-- Run this in your Supabase SQL Editor

-- 1. Crypto: Bitcoin > $100k
INSERT INTO public.markets (
    title,
    description,
    category,
    end_date,
    rules,
    liquidity_b,
    yes_price,
    no_price,
    yes_shares,
    no_shares
) VALUES (
    'Will Bitcoin reach \$100,000 before March 2026?',
    'This market resolves to YES if Bitcoin trades at or above \$100,000 USD on major exchanges (Binance, Coinbase) at any point before March 1st, 2026.',
    'Crypto',
    '2026-03-01 00:00:00+00', 
    'Resolution Source: https://coinmarketcap.com/currencies/bitcoin/ historical data. Market resolves immediately if price is hit.',
    500.0,
    0.5,
    0.5,
    0,
    0
);

-- 2. Sports: Real Madrid Champions League
INSERT INTO public.markets (
    title,
    description,
    category,
    end_date,
    rules,
    liquidity_b,
    yes_price,
    no_price,
    yes_shares,
    no_shares
) VALUES (
    'Will Real Madrid win the 2024/25 Champions League?',
    'This market resolves to YES if Real Madrid C.F. wins the final match of the 2024/25 UEFA Champions League.',
    'Sports',
    '2025-06-01 00:00:00+00',
    'Resolution Source: https://www.uefa.com/uefachampionsleague/. Includes extra time and penalties if applicable.',
    200.0,
    0.5,
    0.5,
    0,
    0
);

-- 3. Pop Culture: GTA VI Release
INSERT INTO public.markets (
    title,
    description,
    category,
    end_date,
    rules,
    liquidity_b,
    yes_price,
    no_price,
    yes_shares,
    no_shares
) VALUES (
    'Will GTA VI be released in 2025?',
    'Resolves to YES if Rockstar Games officially releases Grand Theft Auto VI for purchase/play on any platform by Dec 31, 2025.',
    'Gaming',
    '2025-12-31 23:59:59+00',
    'Resolution Source: https://www.rockstargames.com/. Early access or beta does not count as full release.',
    300.0,
    0.5,
    0.5,
    0,
    0
);

-- 4. Pop Culture: Oscar Best Picture
INSERT INTO public.markets (
    title,
    description,
    category,
    end_date, 
    rules,
    liquidity_b,
    yes_price,
    no_price,
    yes_shares,
    no_shares
) VALUES (
    'Will Christopher Nolan win Best Director at 2026 Oscars?',
    'Resolves to YES if Christopher Nolan wins the Academy Award for Best Director at the 98th Academy Awards ceremony.',
    'Pop Culture',
    '2026-03-30 00:00:00+00',
    'Resolution Source: https://www.oscars.org/.',
    150.0,
    0.5,
    0.5,
    0,
    0
);
