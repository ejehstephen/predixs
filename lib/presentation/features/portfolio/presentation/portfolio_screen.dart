import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:predixs/presentation/features/wallet/providers/wallet_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/position.dart';
import '../../market/presentation/widgets/sell_shares_modal.dart';
import '../providers/portfolio_providers.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  int _selectedIndex = 0; // 0 = Active, 1 = History

  @override
  Widget build(BuildContext context) {
    // Watch all necessary providers
    final positionsAsync = ref.watch(portfolioPositionsProvider);
    final totalValueAsync = ref.watch(totalPortfolioValueProvider);
    final currentValueAsync = ref.watch(portfolioCurrentValueProvider);
    final walletBalanceAsync = ref.watch(walletBalanceProvider);

    final totalProfitAsync = ref.watch(portfolioTotalProfitProvider);
    final totalLossAsync = ref.watch(portfolioTotalLossProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Portfolio',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(portfolioPositionsProvider);
          return Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Net Worth & Stats (Keep these visible on Active Tab)
              _PortfolioSummary(
                totalValueAsync: totalValueAsync,
                walletBalanceAsync: walletBalanceAsync,
                currentValueAsync: currentValueAsync,
                totalProfitAsync: totalProfitAsync,
                totalLossAsync: totalLossAsync,
              ),

              const SizedBox(height: 32),

              // Custom Header Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Text(
                      'Active Positions',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == 0
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 130),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        'History',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _selectedIndex == 1
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              positionsAsync.when(
                data: (allPositions) {
                  final activePositions = allPositions
                      .where((p) => !p.isMarketResolved)
                      .toList();
                  final historyPositions =
                      allPositions.where((p) => p.isMarketResolved).toList()
                        ..sort(
                          (a, b) => b.marketEndTime.compareTo(a.marketEndTime),
                        );

                  final displayList = _selectedIndex == 0
                      ? activePositions
                      : historyPositions;

                  if (displayList.isEmpty) {
                    return _EmptyState(
                      message: _selectedIndex == 0
                          ? 'No active positions'
                          : 'No history yet',
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final pos = displayList[index];
                      // Use different card based on mode
                      if (_selectedIndex == 0) {
                        return _PositionCard(
                          position: pos,
                        ).animate().fadeIn(delay: (50 * index).ms).moveX();
                      } else {
                        return _HistoryItemCard(
                          position: pos,
                        ).animate().fadeIn(delay: (50 * index).ms).moveX();
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final AsyncValue<double> totalValueAsync;
  final AsyncValue<double> walletBalanceAsync;
  final AsyncValue<double> currentValueAsync;
  final AsyncValue<double> totalProfitAsync;
  final AsyncValue<double> totalLossAsync;

  const _PortfolioSummary({
    required this.totalValueAsync,
    required this.walletBalanceAsync,
    required this.currentValueAsync,
    required this.totalProfitAsync,
    required this.totalLossAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Net Worth Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.textPrimary, Color(0xFF2C3E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total Net Worth',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              totalValueAsync.when(
                data: (val) => Text(
                  '₦${val.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().scale(),
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (e, _) => Text(
                  'Error',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Breakdown Grid
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                label: 'Cash Balance',
                value: walletBalanceAsync.when(
                  data: (v) => '₦${v.toStringAsFixed(2)}',
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                label: 'Asset Value',
                value: currentValueAsync.when(
                  data: (v) => '₦${v.toStringAsFixed(2)}',
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.pie_chart_outline,
                iconColor: Colors.purpleAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                label: 'Total Profit',
                value: totalProfitAsync.when(
                  data: (v) => '+₦${v.toStringAsFixed(2)}',
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.trending_up,
                iconColor: AppColors.success,
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                label: 'Total Loss',
                value: totalLossAsync.when(
                  data: (v) => '₦${v.toStringAsFixed(2)}',
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.trending_down,
                iconColor: AppColors.error,
                valueColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final Position position;
  const _HistoryItemCard({required this.position});

  @override
  Widget build(BuildContext context) {
    // Determine user outcome
    // We assume 'resolution' property exists on market, but Position entity might need mapping.
    // If not, we infer from PnL. If PnL > 0 (Winner), PnL < 0 (Loser).
    // Actually, resolved markets set value to 0 or 100 via logic update.
    final isWinner = position.pnl >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
        border: Border.all(
          color: isWinner
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(position.marketEndTime),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isWinner ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isWinner ? "WON" : "LOST",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            position.marketTitle,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "You Picked: ",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                position.side.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                isWinner
                    ? "+₦${position.pnl.toStringAsFixed(2)}"
                    : "-₦${position.value.toStringAsFixed(2)} Loss", // Or display actual PnL
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color:
                  valueColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Position position;

  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final isYes = position.side == 'Yes';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  position.marketTitle,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isYes ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  position.side.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isYes ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PositionStat('Shares', '${position.shares}'),
              _PositionStat(
                'Avg Price',
                '₦${position.avgPrice.toStringAsFixed(2)}',
              ),
              _PositionStat('Value', '₦${position.value.toStringAsFixed(0)}'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P/L',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${position.pnl >= 0 ? '+' : ''}${position.pnlPercent.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: position.pnl >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (DateTime.now().isAfter(position.marketEndTime) &&
              !position.isMarketResolved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.lock, size: 16),
                label: const Text('Market Locked'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else if (position.isMarketResolved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Market Resolved'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppColors.success.withOpacity(0.1),
                  disabledForegroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SellSharesModal(position: position),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Sell Position',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PositionStat extends StatelessWidget {
  final String label;
  final String value;

  const _PositionStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}
