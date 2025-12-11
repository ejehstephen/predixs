import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../domain/entities/market.dart';
import '../../../wallet/providers/wallet_providers.dart';
import '../../providers/market_providers.dart';

class BuySharesModal extends ConsumerStatefulWidget {
  final Market market;
  final bool isYes;

  const BuySharesModal({super.key, required this.market, required this.isYes});

  @override
  ConsumerState<BuySharesModal> createState() => _BuySharesModalState();
}

class _BuySharesModalState extends ConsumerState<BuySharesModal> {
  final _amountController = TextEditingController();
  double _estimatedShares = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateEstimates);
  }

  void _updateEstimates() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = widget.isYes ? widget.market.yesPrice : widget.market.noPrice;
    setState(() {
      _estimatedShares = amount / price;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _placeTrade() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(marketRepositoryProvider);

      // 1. Call API
      await repo.placeTrade(
        marketId: widget.market.id,
        outcome: widget.isYes ? 'yes' : 'no',
        amount: amount,
      );

      // 2. Refresh Providers (Wallet Balance & Market Data)
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(marketProvider(widget.market.id));
      // Optionally invalidate market list if volume/price updates are critical there immediately
      // ref.invalidate(marketListProvider);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop(); // Close modal

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully bought ${_estimatedShares.toStringAsFixed(1)} shares of ${widget.isYes ? 'YES' : 'NO'}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trade failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.isYes ? widget.market.yesPrice : widget.market.noPrice;
    final color = widget.isYes ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(
        24,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buy ${widget.isYes ? 'Yes' : 'No'}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const Gap(8),
          Text(
            widget.market.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(24),
          Text(
            'Current Price: ₦${price.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: '₦ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Shares:',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  _estimatedShares.toStringAsFixed(2),
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeTrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Confirm Buy',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
