import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// --- Provider ---
final pendingWithdrawalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('withdraw_requests')
          .select('*, transaction_id') // Explicitly fetch this column
          .or('status.eq.manual_review,status.eq.processing')
          .order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    });

class AdminWithdrawalsScreen extends ConsumerWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(pendingWithdrawalsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pending Withdrawals',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: withdrawalsAsync.when(
        data: (withdrawals) {
          if (withdrawals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const Gap(16),
                  Text(
                    "All caught up!",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: withdrawals.length,
            separatorBuilder: (_, __) => const Gap(16),
            itemBuilder: (context, index) {
              final item = withdrawals[index];
              return _WithdrawalCard(
                item: item,
                onProcessed: () => ref.refresh(pendingWithdrawalsProvider),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _WithdrawalCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onProcessed;

  const _WithdrawalCard({required this.item, required this.onProcessed});

  @override
  State<_WithdrawalCard> createState() => _WithdrawalCardState();
}

class _WithdrawalCardState extends State<_WithdrawalCard> {
  bool _isLoading = false;

  Future<void> _markAsPaid() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final requestId = widget.item['id'];
      final transactionId =
          widget.item['transaction_id']; // This is the Single Truth

      print("DEBUG: Request ID: $requestId");
      print("DEBUG: Transaction ID Linked: $transactionId"); // <--- Debug log

      // 1. Update Request to Success
      await supabase
          .from('withdraw_requests')
          .update({'status': 'completed'})
          .eq('id', requestId);

      // 2. Handle Transaction Record (Option A: Update the Linked Transaction!)
      if (transactionId != null) {
        // Correct Model: Update the existing transaction
        await supabase
            .from('transactions')
            .update({
              'status': 'completed', // Updates the specific transaction
              'metadata': {
                'method': 'admin_approval',
                'original_request_id': requestId,
                // Merge with existing metadata if needed, but this is fine
              },
            })
            .eq('id', transactionId);
      } else {
        // Fallback for OLD records (Backwards Compatibility)
        // Force Insert New Success Record because logic was missing before
        await supabase.from('transactions').insert({
          'user_id': widget.item['user_id'],
          'type': 'withdraw_debit',
          'amount': widget.item['amount'] as num,
          'status': 'completed',
          'metadata': {
            'method': 'manual_admin_override_legacy',
            'original_request_id': requestId,
          },
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marked as Paid ✅')));

        // 3. Send Notification to User
        await supabase.from('notifications').insert({
          'user_id': widget.item['user_id'],
          'title': 'Withdrawal Successful',
          'body':
              'Your withdrawal of ₦${widget.item['amount']} has been processed successfully.',
          'type': 'wallet',
          'is_read': false,
        });

        widget.onProcessed();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // Triggers the Refund RPC
      await supabase.rpc(
        'refund_failed_withdrawal',
        params: {
          'p_request_id': widget.item['id'],
          'p_reason': 'Admin Rejected: Manual Review Failed',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rejected & Refunded ↩️')));
        widget.onProcessed();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.item['amount'];
    final bankName = widget.item['bank_name'] ?? 'Unknown Bank';
    final accNum = widget.item['account_number'] ?? 'Unknown Acc';
    final accName = widget.item['account_name'] ?? 'Unknown Name';
    final status = widget.item['status'];
    final date = DateTime.parse(widget.item['created_at']);

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₦$amount',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Builder(
                  builder: (context) {
                    Color statusColor;
                    final s = status.toString().toLowerCase();
                    if (['completed', 'success'].contains(s)) {
                      statusColor = Colors.green;
                    } else if (['failed', 'rejected'].contains(s)) {
                      statusColor = Colors.red;
                    } else {
                      statusColor = Colors.orange;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        status.toString().toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Gap(8),
            Text(
              '$accName',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              '$bankName - $accNum',
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const Gap(4),
            Text(
              DateFormat('MMM dd, hh:mm a').format(date),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const Gap(8),
                  ElevatedButton.icon(
                    onPressed: _markAsPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Mark Paid",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
