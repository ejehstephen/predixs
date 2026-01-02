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

//         // 3. Parse Body & Action
//         const body = await req.json();
//         // Default to 'initialize' if action is missing (Legacy/Deposit flow)
//         const action = body.action || 'initialize';
//         const payload = body;

//         switch (action) {
//             case 'initialize':
//                 return await handleInitialize(payload, user);
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

// // 1. Initialize Transaction (Deposit)
// async function handleInitialize({ email, amount, reference }, user) {
//     if (!email || !amount) throw new Error("Missing email or amount");

//     const paystackRes = await fetch("https://api.paystack.co/transaction/initialize", {
//         method: "POST",
//         headers: {
//             Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
//             "Content-Type": "application/json",
//         },
//         body: JSON.stringify({
//             email,
//             amount: Math.round(amount * 100), // Convert to Kobo
//             reference: reference,
//             callback_url: "https://standard.paystack.co/close",
//             metadata: {
//                 user_id: user.id,
//                 custom_fields: [
//                     { display_name: "User ID", variable_name: "user_id", value: user.id }
//                 ]
//             },
//             channels: ["card", "bank", "ussd", "qr", "mobile_money", "bank_transfer"],
//         }),
//     });

//     const data = await paystackRes.json();
//     if (!data.status) throw new Error(data.message || "Paystack initialization failed");

//     return new Response(
//         JSON.stringify({
//             access_code: data.data.access_code,
//             reference: data.data.reference,
//             authorization_url: data.data.authorization_url,
//         }),
//         {
//             headers: { ...corsHeaders, "Content-Type": "application/json" },
//             status: 200,
//         }
//     );
// }

// // 2. Get Banks
// async function handleGetBanks() {
//     const res = await fetch("https://api.paystack.co/bank?currency=NGN", {
//         headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
//     });
//     const data = await res.json();
//     if (!data.status) throw new Error(data.message || "Failed to fetch banks");

//     return new Response(JSON.stringify(data), {
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//         status: 200,
//     });
// }

// // 3. Resolve Account
// async function handleResolveAccount({ account_number, bank_code }) {
//     if (!account_number || !bank_code) throw new Error("Missing account details");

//     const url = `https://api.paystack.co/bank/resolve?account_number=${account_number}&bank_code=${bank_code}`;
//     const res = await fetch(url, {
//         headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
//     });
//     const data = await res.json();

//     return new Response(JSON.stringify(data), {
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//         status: 200,
//     });
// }

// // 4. Initiate Transfer (Withdrawal)
// async function handleInitiateTransfer(supabase, { amount, bank_code, account_number, account_name, bank_name }, userId) {
//     // A. Lock Funds & Verify KYC (RPC)
//     const { data: lockData, error: lockError } = await supabase.rpc('lock_funds_for_withdrawal', {
//         p_amount: amount
//     });

//     if (lockError) throw new Error(lockError.message);

//     const requestId = lockData.request_id;

//     console.log("Creating Recipient for:", { account_name, account_number, bank_code }); // DEBUG LOG

//     try {
//         // B. Create Recipient
//         // FIX: '001' is valid for Resolution but invalid for Recipient Creation.
//         // We swap it to '057' (Zenith) which works with '0000000000' for test transfers.
//         const requestBankCode = bank_code === '001' ? '057' : bank_code;

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
//                 bank_code: requestBankCode,
//                 currency: "NGN"
//             })
//         });
//         const recData = await recRes.json();
//         console.log("Recipient Response:", JSON.stringify(recData)); // DEBUG

//         if (!recData.status) throw new Error(recData.message || "Failed to create recipient");

//         const recipientCode = recData.data.recipient_code;

//         // C. Initiate Transfer
//         const txRes = await fetch("https://api.paystack.co/transfer", {
//             method: "POST",
//             headers: {
//                 Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
//                 "Content-Type": "application/json"
//             },
//             body: JSON.stringify({
//                 source: "balance",
//                 amount: Math.round(amount * 100),
//                 recipient: recipientCode,
//                 reason: `Withdrawal for User ${userId}`,
//                 reference: `${requestId}`
//             })
//         });
//         const txData = await txRes.json();

//         if (!txData.status) throw new Error(txData.message || "Transfer initiation failed");

//         // D. Update Request Record (Success)
//         await supabase
//             .from('withdraw_requests')
//             .update({
//                 bank_code,
//                 bank_name,
//                 account_number,
//                 account_name,
//                 recipient_code: recipientCode,
//                 transfer_code: txData.data.transfer_code,
//                 status: txData.data.status,
//                 reference: requestId
//             })
//             .eq('id', requestId);

//         return new Response(JSON.stringify({ success: true, message: "Transfer Initiated", data: txData.data }), {
//             headers: { ...corsHeaders, "Content-Type": "application/json" },
//             status: 200,
//         });

//     } catch (e) {
//         console.error("Transfer Error, Rolling back:", e);
//         const errorMessage = e.message || "Transfer Failed";

//         // --- MANUAL FALLBACK FOR STARTER BUSINESS ---
//         // If Paystack rejects due to policy (Starter Business), queue for manual review.
//         if (errorMessage.toLowerCase().includes("starter business")) {
//             console.log("Enabling Manual Mode for Request:", requestId);

//             // 1. Update Request Status to 'manual_review'
//             await supabase
//                 .from('withdraw_requests')
//                 .update({
//                     status: 'manual_review',
//                     bank_code,
//                     bank_name,
//                     account_number,
//                     account_name,
//                     // Store error reason for context
//                     reference: `Manual Trigger: ${errorMessage}`
//                 })
//                 .eq('id', requestId);

//             // 2. Update Transaction to 'pending_manual' (so user sees it's not "Completed" yet)
//             const transactionId = lockData.transaction_id;
//             if (transactionId) {
//                 await supabase
//                     .from('transactions')
//                     .update({ status: 'pending_manual' })
//                     .eq('id', transactionId);
//             }

//             // 3. Return SUCCESS to frontend (with special message)
//             return new Response(JSON.stringify({
//                 success: true,
//                 message: "Request queued for manual processing (24-48h)",
//                 data: { status: "manual_review" }
//             }), {
//                 headers: { ...corsHeaders, "Content-Type": "application/json" },
//                 status: 200,
//             });
//         }

//         // --- STANDARD AUTO-REFUND LOGIC ---
//         try {
//             await supabase.rpc('refund_failed_withdrawal', {
//                 p_request_id: requestId,
//                 p_reason: errorMessage
//             });
//             console.log("Refund successful for request:", requestId);
//         } catch (refundError) {
//             console.error("CRITICAL: Refund failed!", refundError);
//         }

//         throw e; // Re-throw to inform client
//     }
// }
