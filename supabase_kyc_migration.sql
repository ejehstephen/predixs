-- Add NIN columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS nin text,
ADD COLUMN IF NOT EXISTS nin_verified boolean DEFAULT false;

-- Policy to allow users to update their own NIN (if it's null)
-- Prevents changing NIN once set (security)
CREATE POLICY "Users can set their NIN" ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id 
  AND (nin IS NULL OR nin = '') -- Only allow setting if currently empty
);
