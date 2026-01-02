import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:predixs/core/services/lmsr_service.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../domain/entities/position.dart';
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../../wallet/providers/wallet_providers.dart';
import '../../providers/market_providers.dart';

class SellSharesModal extends ConsumerStatefulWidget {
  final Position position;

  const SellSharesModal({super.key, required this.position});

  @override
  ConsumerState<SellSharesModal> createState() => _SellSharesModalState();
}

class _SellSharesModalState extends ConsumerState<SellSharesModal> {
  final _amountController = TextEditingController(); // Input is SHARES
  double _estimatedReturn = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateEstimates);
  }

  void _updateEstimates() {
    final sharesToSell = double.tryParse(_amountController.text) ?? 0;

    // Fetch market state for accurate LMSR calc
    // We use ref.read because we are in a callback
    final marketAsync = ref.read(marketProvider(widget.position.marketId));
    final market = marketAsync.value;

    if (market != null) {
      // LMSR Estimate
      final returnAmount = LmsrService.estimateSellReturn(
        sharesToSell: sharesToSell,
        currentYesShares: market.yesShares,
        currentNoShares: market.noShares,
        b: market.liquidityB,
        isYesOutcome: widget.position.side == 'Yes', // 'Yes' or 'No'
      );

      setState(() {
        _estimatedReturn = returnAmount;
      });
    } else {
      // Fallback if market not loaded (should generally not happen if we came from portfolio -> detail)
      // But if came from portfolio and market details not cached, we might need simple fallback
      // For now, 0 or simple price * shares
      setState(() {
        // Simple fallback: Shares * Current Price (Approx)
        _estimatedReturn = sharesToSell * widget.position.currentPrice;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sellShares() async {
    final shares = double.tryParse(_amountController.text);
    if (shares == null || shares <= 0) return;

    if (shares > widget.position.shares) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sell more than you own!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (DateTime.now().isAfter(widget.position.marketEndTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sell: Market is locked for trading!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(marketRepositoryProvider);

      // 1. Call API
      await repo.sellShares(
        marketId: widget.position.marketId,
        outcome: widget.position.side,
        shares: shares,
      );

      // 2. Refresh Providers
      ref.invalidate(walletBalanceProvider); // Update cash
      ref.invalidate(walletTransactionsProvider); // History
      ref.invalidate(portfolioPositionsProvider); // Remove/Update position
      ref.invalidate(marketListProvider); // Update market stats context-wide

      // If we are on a market detail screen, we might want to refresh that too
      // ref.invalidate(marketProvider(widget.position.marketId));

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop(); // Close modal

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully sold ${shares.toStringAsFixed(1)} shares!',
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
            content: Text('Sell failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sell usually implies exiting, so maybe a neutral or warning color?
    // Or just Primary color. Let's use Orange for "Action".
    const color = Colors.orange;

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
                'Sell ${widget.position.side}',
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
            widget.position.marketTitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Owned Shares: ${widget.position.shares.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Price: ₦${widget.position.currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
              prefixText: 'Shares: ',
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
                borderSide: const BorderSide(color: color),
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
                  'Est. Return:',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  '₦${_estimatedReturn.toStringAsFixed(2)}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
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
              onPressed: _isLoading ? null : _sellShares,
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
                      'Confirm Sell',
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
