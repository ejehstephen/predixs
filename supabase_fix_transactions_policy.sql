-- =================================================================
-- FIX: Allow Admins to Manage Transactions
-- =================================================================

-- 1. Check current policies (Optional, mainly for context)
-- Existing: "Users can view own transactions"

-- 2. Allow Admins to VIEW all transactions
create policy "Admins can view all transactions"
on public.transactions
for select
using (
  public.is_admin()
);

-- 3. Allow Admins to INSERT transactions (Creating the "Success" record if missing)
create policy "Admins can insert transactions"
on public.transactions
for insert
with check (
  public.is_admin()
);

-- 4. Allow Admins to UPDATE transactions (Marking existing as "completed")
create policy "Admins can update transactions"
on public.transactions
for update
using (
  public.is_admin()
);

-- Note: public.is_admin() function must exist (created in previous steps).
-- If it doesn't exist, this will error. But we assume it exists from `supabase_rls_admins.sql`.
