-- ==========================================
-- NOTIFICATION SYSTEM (Production Ready Triggers)
-- ==========================================

-- 1. Ensure Notifications Table Exists
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type varchar(32) DEFAULT 'info', -- 'info', 'success', 'warning', 'error'
  is_read boolean DEFAULT false,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);


-- ==========================================
-- TRIGGER 1: NOTIFY ON NEW MARKET
-- "New Market Alert: Will BTC hit...?"
-- ==========================================

create or replace function notify_on_new_market()
returns trigger
language plpgsql
security definer
as $$
declare
  v_user record;
begin
  -- LOOP INSERTS for all users. 
  -- *NOTE*: At scale (>10k users), this should be done via Edge Function or Pub/Sub pattern, not direct SQL trigger.
  -- For MVP, this ensures every user sees the new market.
  
  for v_user in select id from auth.users
  loop
    insert into public.notifications (user_id, title, body, type, metadata)
    values (
      v_user.id,
      'New Market: ' || NEW.category,
      'Can you predict: ' || NEW.title || '? Trade now!',
      'info',
      jsonb_build_object('market_id', NEW.id)
    );
  end loop;
  
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS on_market_created ON public.markets;
CREATE TRIGGER on_market_created
  AFTER INSERT ON public.markets
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_new_market();


-- ==========================================
-- TRIGGER 2: NOTIFY ON MARKET RESOLUTION
-- "Market Resolved: You Won/Lost!"
-- ==========================================

create or replace function notify_on_market_resolve()
returns trigger
language plpgsql
security definer
as $$
declare
  v_pos record;
  v_title text;
  v_body text;
  v_type text;
begin
  -- Only run if is_resolved changed from false to true
  if OLD.is_resolved = false and NEW.is_resolved = true then
    
    -- Find all users who had a position in this market
    for v_pos in 
      select * from public.positions where market_id = NEW.id
    loop
      
      if v_pos.side = NEW.resolution_outcome then
        v_title := 'Winning Payout! 🎉';
        v_body := 'You won on "' || NEW.title || '"! Your winnings have been deposited.';
        v_type := 'success';
      else
        v_title := 'Market Resolved';
        v_body := 'The market "' || NEW.title || '" resolved to ' || NEW.resolution_outcome || '. Better luck next time!';
        v_type := 'info';
      end if;
      
      insert into public.notifications (user_id, title, body, type, metadata)
      values (
        v_pos.user_id,
        v_title,
        v_body,
        v_type,
        jsonb_build_object('market_id', NEW.id)
      );
      
    end loop;
    
  end if;
  
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS on_market_resolved ON public.markets;
CREATE TRIGGER on_market_resolved
  AFTER UPDATE ON public.markets
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_market_resolve();


-- ==========================================
-- TRIGGER 3: NOTIFY ON TRADE / TRANSACTION
-- "Trade Executed / Deposit Success"
-- ==========================================

create or replace function notify_on_transaction()
returns trigger
language plpgsql
security definer
as $$
declare
  v_title text;
  v_body text;
  v_type text := 'info';
begin
  -- Determine message based on type
  if NEW.type = 'buy' then
    v_title := 'Trade Executed';
    v_body := 'You bought shares.'; -- Can be more specific if we join markets, but transaction table is generic
    v_type := 'success';
  elsif NEW.type = 'sell' then
    v_title := 'Shares Sold';
    v_body := 'You sold your position.';
    v_type := 'success';
  elsif NEW.type = 'deposit' then
    v_title := 'Deposit Successful';
    v_body := 'Your wallet has been funded with ₦' || abs(NEW.amount);
    v_type := 'success';
  elsif NEW.type = 'payout' then
     -- Handled by market resolution trigger generally, but good as backup or immediate feedback?
     -- Let's skip to avoid double notification with Resolution Trigger
     return NEW; 
  end if;

  insert into public.notifications (user_id, title, body, type)
  values (NEW.user_id, v_title, v_body, v_type);
  
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS on_transaction_created ON public.transactions;
CREATE TRIGGER on_transaction_created
  AFTER INSERT ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_transaction();
