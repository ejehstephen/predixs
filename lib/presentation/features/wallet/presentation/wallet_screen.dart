import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/wallet_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/paystack_service.dart';
import '../../../../core/extensions/exception_extension.dart';
import 'widgets/withdrawal_modal.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final transactions = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Wallet',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF1A1C30), const Color(0xFF0F1120)]
                      : [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  balance.when(
                    data: (value) => Text(
                      '₦${value.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () =>
                        const CircularProgressIndicator(color: Colors.white),
                    error: (e, s) => Text(
                      'Error: $e',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _handleTransaction(context, ref, isDeposit: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Deposit'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleTransaction(
                            context,
                            ref,
                            isDeposit: false,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Withdraw'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            const SizedBox(height: 16),

            transactions.when(
              data: (txs) {
                if (txs.isEmpty) {
                  return const Center(child: Text('No transactions yet'));
                }
                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: txs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    // If it's a withdrawal, we treat it as negative for display, even if DB stores it as positive
                    final isDebit =
                        tx.type == 'withdraw_debit' || tx.type == 'buy_shares';
                    final isPositive = !isDebit && tx.amount > 0;

                    // Display amount logic
                    final displayAmount = isDebit
                        ? -tx.amount.abs()
                        : tx.amount;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  ((tx.status == 'completed' ||
                                              tx.status == 'success')
                                          ? AppColors.success
                                          : (isPositive
                                                ? AppColors.success
                                                : AppColors.error))
                                      .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color:
                                  (tx.status == 'completed' ||
                                      tx.status == 'success')
                                  ? AppColors.success
                                  : (isPositive
                                        ? AppColors.success
                                        : AppColors.error),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTransactionType(tx.type),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(tx.date),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : '-'}₦${displayAmount.abs().toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isPositive
                                      ? AppColors.success
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  // Actually, standard is usually Black for debit, Green for credit.
                                  // Or Red for debit. Let's stick to textPrimary (Black/Dark) for debit for now to be safe, or Error (Red).
                                  // Existing code used textPrimary for non-positive.
                                ),
                              ),
                              Text(
                                _formatTransactionStatus(tx.status),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: _getStatusColor(tx.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 100).ms);
                  },
                );
              },

              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTransaction(
    BuildContext context,
    WidgetRef ref, {
    required bool isDeposit,
  }) async {
    final amount = await _showAmountDialog(context, isDeposit: isDeposit);
    if (amount == null) return;

    try {
      if (isDeposit) {
        // --- PAYSTACK INTEGRATION ---
        final user = Supabase.instance.client.auth.currentUser;
        final email = user?.email ?? 'customer@predixs.com';

        // simple unique reference
        final reference = 'Dep_${DateTime.now().millisecondsSinceEpoch}';

        final response = await PaystackService().chargeCard(
          context: context,
          amount: amount,
          email: email,
          reference: reference,
        );

        if (response != null && response.status) {
          // Payment Successful on Paystack Gateway
          // Now verify/credit on Backend (Simulated here by calling repository direct)
          // In production, you should verify the reference on backend before crediting.
          await ref.read(walletRepositoryProvider).deposit(amount);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment Successful: Ref ${response.reference}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          // Payment Failed or Cancelled
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment Cancelled or Failed: ${response?.message ?? "Unknown"}',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return; // Do not refresh balance if failed
        }
      } else {
        // --- WITHDRAWAL (AUTOMATED) ---
        final result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true, // Allow full height for keyboard
          backgroundColor: Colors.transparent,
          builder: (context) => const WithdrawalModal(),
        );

        if (result == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Withdrawal Initiated Successfully! Funds will reflect shortly.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          // Cancelled or dismissed
          return;
        }
      }

      // Refresh data (Works for both Deposit and Withdraw success)
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toUserFriendlyMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<double?> _showAmountDialog(
    BuildContext context, {
    required bool isDeposit,
  }) {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeposit ? 'Deposit Funds' : 'Withdraw Funds'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (₦)',
            hintText: 'e.g. 5000',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(context, val);
              }
            },
            child: Text(isDeposit ? 'Deposit' : 'Withdraw'),
          ),
        ],
      ),
    );
  }

  String _formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'withdraw_debit':
        return 'Withdrawal';
      case 'deposit':
        return 'Deposit';
      case 'refund':
        return 'Refund';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  String _formatTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Pending';
      case 'pending_manual':
        return 'Under Review';
      case 'completed':
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      default:
        return status.capitalize();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'processing':
      case 'pending':
      case 'pending_manual':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
