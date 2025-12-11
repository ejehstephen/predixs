-- Create Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type varchar(32) DEFAULT 'info', -- 'info', 'success', 'warning', 'error'
  is_read boolean DEFAULT false,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- RLS (Row Level Security) - good practice even if disabled globally for now
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Trigger to create a notification on trade? 
-- (Optional: For now, we'll manually insert via app or edge function, 
-- but simpler to just query generic 'trades' if we wanted specific trade notifs. 
-- However, user wants a dedicated notification screen, so a table is best.)

-- Insert some dummy notifications for testing current user (requires you to replace ID or run generic)
-- We won't insert dummy data here to avoid ID mismatch constraints.
