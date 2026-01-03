-- CHECK LATEST WITHDRAWAL REQUESTS
-- Run this to see if the `transaction_id` is actually being saved.

select 
  id as request_id, 
  created_at, 
  status, 
  amount, 
  transaction_id 
from 
  public.withdraw_requests 
order by 
  created_at desc 
limit 5;
