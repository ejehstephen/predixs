import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:predixs/presentation/features/wallet/providers/wallet_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/position.dart';
import '../providers/portfolio_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all necessary providers
    final positionsAsync = ref.watch(portfolioPositionsProvider);
    final totalValueAsync = ref.watch(totalPortfolioValueProvider);
    final investedAsync = ref.watch(portfolioInvestedProvider);
    final currentValueAsync = ref.watch(portfolioCurrentValueProvider);

    // Calculate PnL from AsyncValues if available, else 0
    final invested = investedAsync.asData?.value ?? 0.0;
    final currentVal = currentValueAsync.asData?.value ?? 0.0;
    final pnl = currentVal - invested;
    final pnlPercent = invested == 0 ? 0.0 : (pnl / invested) * 100;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Portfolio',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
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
              // Portfolio Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Portfolio Value (Cash + Assets)',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    totalValueAsync.when(
                      data: (val) => Text(
                        '₦${val.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().scale(),
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'Error',
                        style: GoogleFonts.outfit(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            label: 'Invested',
                            value: '₦${invested.toStringAsFixed(0)}',
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: _SummaryItem(
                            label: 'Total P/L',
                            value:
                                '${pnl >= 0 ? '+' : ''}₦${pnl.toStringAsFixed(0)}',
                            valueColor: pnl >= 0
                                ? AppColors.success
                                : AppColors.error,
                            subValue: '${pnlPercent.toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Active Positions',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              positionsAsync.when(
                data: (positions) {
                  if (positions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Text(
                        'No active positions',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: positions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final pos = positions[index];
                      return _PositionCard(
                        position: pos,
                      ).animate().fadeIn(delay: (100 * index).ms).moveX();
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ), // SingleChildScrollView
      ), // RefreshIndicator
    ); // Scaffold
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subValue;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: GoogleFonts.inter(
              color: valueColor ?? AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
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
        color: Colors.white,
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
                    color: AppColors.textPrimary,
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
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
