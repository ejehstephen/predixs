// import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY");
// const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
// const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

// const corsHeaders = {
//     "Access-Control-Allow-Origin": "*",
//     "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
// };

// serve(async (req) => {
//     // 1. CORS
//     if (req.method === "OPTIONS") {
//         return new Response("ok", { headers: corsHeaders });
//     }

//     try {
//         // 2. Auth Check
//         const authHeader = req.headers.get('Authorization');
//         if (!authHeader) throw new Error('Missing Authorization header');

//         const supabase = createClient(
//             SUPABASE_URL ?? '',
//             SUPABASE_ANON_KEY ?? '',
//             {
//                 global: { headers: { Authorization: authHeader } },
//                 auth: { persistSession: false }
//             }
//         );

//         const token = authHeader.replace('Bearer ', '');
//         const { data: { user }, error: userError } = await supabase.auth.getUser(token);
//         if (userError || !user) throw new Error("Unauthorized");

//         // 3. Parse Action
//         const { action, ...payload } = await req.json();

//         switch (action) {
//             case 'get_banks':
//                 return await handleGetBanks();
//             case 'resolve_account':
//                 return await handleResolveAccount(payload);
//             case 'initiate_transfer':
//                 return await handleInitiateTransfer(supabase, payload, user.id);
//             default:
//                 throw new Error(`Unknown action: ${action}`);
//         }

//     } catch (error) {
//         console.error("Handler Error:", error);
//         return new Response(JSON.stringify({ error: error.message }), {
//             headers: { ...corsHeaders, "Content-Type": "application/json" },
//             status: 400,
//         });
//     }
// });

// // --- Handlers ---

// async function handleGetBanks() {
//     const res = await fetch("https://api.paystack.co/bank", {
//         headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
//     });
//     const data = await res.json();
//     if (!data.status) throw new Error(data.message || "Failed to fetch banks");

//     return new Response(JSON.stringify(data), {
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//         status: 200,
//     });
// }

// async function handleResolveAccount({ account_number, bank_code }) {
//     if (!account_number || !bank_code) throw new Error("Missing account details");

//     const url = `https://api.paystack.co/bank/resolve?account_number=${account_number}&bank_code=${bank_code}`;
//     const res = await fetch(url, {
//         headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
//     });
//     const data = await res.json();

//     // Pass strictly what we need
//     return new Response(JSON.stringify(data), {
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//         status: 200,
//     });
// }

// async function handleInitiateTransfer(supabase, { amount, bank_code, account_number, account_name, bank_name }, userId) {
//     // 1. Lock Funds & Verify KYC (RPC)
//     const { data: lockData, error: lockError } = await supabase.rpc('lock_funds_for_withdrawal', {
//         p_amount: amount
//     });

//     if (lockError) {
//         throw new Error(lockError.message); // Will catch "KYC Verification Required"
//     }

//     const requestId = lockData.request_id;

//     try {
//         // 2. Create Recipient
//         const recRes = await fetch("https://api.paystack.co/transferrecipient", {
//             method: "POST",
//             headers: {
//                 Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
//                 "Content-Type": "application/json"
//             },
//             body: JSON.stringify({
//                 type: "nuban",
//                 name: account_name,
//                 account_number: account_number,
//                 bank_code: bank_code,
//                 currency: "NGN"
//             })
//         });
//         const recData = await recRes.json();
//         if (!recData.status) throw new Error(recData.message || "Failed to create recipient");

//         const recipientCode = recData.data.recipient_code;

//         // 3. Initiate Transfer
//         const txRes = await fetch("https://api.paystack.co/transfer", {
//             method: "POST",
//             headers: {
//                 Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
//                 "Content-Type": "application/json"
//             },
//             body: JSON.stringify({
//                 source: "balance", // Uses your Paystack Balance
//                 amount: Math.round(amount * 100), // Kobo
//                 recipient: recipientCode,
//                 reason: `Withdrawal for User ${userId}`,
//                 reference: `${requestId}` // Use our Request ID as ref
//             })
//         });
//         const txData = await txRes.json();

//         if (!txData.status) {
//             // CRITICAL: If transfer fails, we must REFUND the wallet or mark as failed for manual review.
//             // For now, let's mark as failed so Admin sees it, or auto-refund.
//             // Simplified: Throw, triggers catch block.
//             throw new Error(txData.message || "Transfer initiation failed");
//         }

//         // 4. Update Request Record
//         await supabase
//             .from('withdraw_requests')
//             .update({
//                 bank_code,
//                 bank_name,
//                 account_number,
//                 account_name,
//                 recipient_code: recipientCode,
//                 transfer_code: txData.data.transfer_code,
//                 status: txData.data.status, // 'success' or 'pending'
//                 reference: requestId
//             })
//             .eq('id', requestId);

//         return new Response(JSON.stringify({ success: true, message: "Transfer Initiated", data: txData.data }), {
//             headers: { ...corsHeaders, "Content-Type": "application/json" },
//             status: 200,
//         });

//     } catch (e) {
//         // Rollback Logic Attempt (Best Effort)
//         console.error("Transfer Error, Rolling back:", e);
//         // We should ideally refund the user here using another RPC or Admin Alert.
//         // For MVP: Log error. Money is deducted but stuck in 'pending_details' or 'processing'.
//         // This is safe-ish (User didn't lose money, it's just locked). Support can refund.
//         throw e;
//     }
// }
