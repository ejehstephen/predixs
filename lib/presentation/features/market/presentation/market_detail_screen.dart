import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/market.dart';
import '../providers/market_providers.dart';
import 'widgets/buy_shares_modal.dart';

class MarketDetailScreen extends ConsumerWidget {
  final String marketId;

  const MarketDetailScreen({super.key, required this.marketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketAsync = ref.watch(marketProvider(marketId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: Theme.of(context).iconTheme.color,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Market Detail',
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: Theme.of(context).iconTheme.color,
            onPressed: () async {
              final market = marketAsync.asData?.value;
              if (market != null) {
                try {
                  await Share.share(
                    'Check out this trade on Predixs!\n${market.title}\n\nView Trade: io.supabase.predixs://app/market/${market.id}\n\nDon\'t have the app? Download it to start trading!',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not share: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: marketAsync.when(
        data: (market) => _buildContent(context, market),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: marketAsync.asData?.value != null
          ? _buildBottomBar(context, marketAsync.asData!.value)
          : null,
    );
  }

  Widget _buildContent(BuildContext context, Market market) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and Status Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  market.category,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Gap(8),
              if (market.status == 'resolved')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const Gap(4),
                      Text(
                        'Resolved',
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (DateTime.now().isAfter(market.endTime))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 14, color: Colors.orange),
                      const Gap(4),
                      Text(
                        'Locked',
                        style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Open - Show Countdown or simply "Open"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const Gap(4),
                      Text(
                        'Open', // could be improved with countdown later
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ).animate().fadeIn().moveX(begin: -10, end: 0),
          const Gap(16),

          // Title
          Text(
            market.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).moveY(begin: 10, end: 0),
          const Gap(24),

          // Chart Section
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price History (24h)',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '+5.2%',
                      style: GoogleFonts.robotoMono(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final historyAsync = ref.watch(
                        marketHistoryProvider(market.id),
                      );
                      return historyAsync.when(
                        data: (history) => _MarketChart(
                          isYesTrend: market.yesPrice > 0.5,
                          history: history,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const Gap(32),

          // Prediction Cards
          Text(
            'Make a Prediction',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const Gap(16),

          Row(
            children: [
              Expanded(
                child: _PredictionCard(
                  label: 'YES',
                  price: market.yesPrice,
                  color: AppColors.success,
                  onTap: () {},
                ).animate().moveX(begin: -20, end: 0, delay: 400.ms),
              ),
              const Gap(16),
              Expanded(
                child: _PredictionCard(
                  label: 'NO',
                  price: market.noPrice,
                  color: AppColors.error,
                  onTap: () {},
                ).animate().moveX(begin: 20, end: 0, delay: 400.ms),
              ),
            ],
          ),
          const Gap(32),

          // Details Stats
          _buildStatsGrid(context, market).animate().fadeIn(delay: 500.ms),

          const Gap(100), // Bottom padding for sticky bar
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Market market) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _StatTile(
          label: 'Volume',
          value: '₦${(market.volume / 1000).toStringAsFixed(1)}k',
        ),
        _StatTile(
          label: 'Liquidity',
          value: 'B: ${market.liquidityB.toStringAsFixed(0)}',
        ),
        _StatTile(
          label: 'End Date',
          value:
              '${market.endTime.day}/${market.endTime.month}/${market.endTime.year}',
        ),
        _StatTile(
          label: 'Rules',
          value: 'View Rules',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24).copyWith(bottom: 48),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(24),
                    Text(
                      'Market Rules',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Gap(16),
                    Text(
                      market.rules ??
                          'Standard market rules apply. Market resolves based on the specific outcome defined in the title/description.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Market market) {
    final isLocked = DateTime.now().isAfter(market.endTime);
    final isResolved = market.status == 'resolved';
    final canTrade = !isLocked && !isResolved;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canTrade)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isResolved
                          ? Icons.check_circle_outline
                          : Icons.lock_outline,
                      color: isResolved
                          ? AppColors.success
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const Gap(8),
                    Text(
                      isResolved
                          ? 'Market Resolved'
                          : 'Market Locked - Waiting for Resolution',
                      style: GoogleFonts.inter(
                        color: isResolved
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canTrade
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  BuySharesModal(market: market, isYes: true),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF22C55E,
                      ), // Standard Vibrant Green
                      disabledBackgroundColor: const Color(
                        0xFF22C55E,
                      ).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buy YES ₦${market.yesPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canTrade
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  BuySharesModal(market: market, isYes: false),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFEF4444,
                      ), // Standard Vibrant Red
                      disabledBackgroundColor: const Color(
                        0xFFEF4444,
                      ).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buy NO ₦${market.noPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
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

class _PredictionCard extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.label,
    required this.price,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
              const Gap(8),
              Text(
                '₦${(price * 100).toStringAsFixed(1)}',
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const Gap(8),
              LinearProgressIndicator(
                value: price,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
              ),
              const Gap(8),
              Text(
                '${(price * 100).toStringAsFixed(0)}% Chance',
                style: GoogleFonts.inter(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatTile({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketChart extends StatelessWidget {
  final bool isYesTrend;
  final List<MarketPricePoint> history;

  const _MarketChart({required this.isYesTrend, required this.history});

  @override
  Widget build(BuildContext context) {
    final color = isYesTrend ? AppColors.success : AppColors.error;

    if (history.isEmpty) {
      return Center(
        child: Text(
          'No history yet',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    // Map history to spots (X: Index, Y: Yes Price)
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.yesPrice);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        // Add some padding to Y axis
        minY: 0,
        maxY: 1.0,
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
