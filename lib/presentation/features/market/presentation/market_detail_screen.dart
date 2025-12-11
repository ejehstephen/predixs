import 'package:fl_chart/fl_chart.dart';
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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Market Detail',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppColors.textPrimary,
            onPressed: () {},
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
          // Category Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ).animate().fadeIn().moveX(begin: -10, end: 0),
          const Gap(16),

          // Title
          Text(
            market.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).moveY(begin: 10, end: 0),
          const Gap(24),

          // Chart Section
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
                        color: AppColors.textSecondary,
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
                  child: _MarketChart(isYesTrend: market.yesPrice > 0.5),
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
              color: AppColors.textPrimary,
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
          _buildStatsGrid(market).animate().fadeIn(delay: 500.ms),

          const Gap(100), // Bottom padding for sticky bar
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Market market) {
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
          value: '₦${(market.initialLiquidity / 1000).toStringAsFixed(1)}k',
        ),
        _StatTile(
          label: 'End Date',
          value:
              '${market.endTime.day}/${market.endTime.month}/${market.endTime.year}',
        ),
        const _StatTile(label: 'Rules', value: 'View Rules'),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Market market) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        BuySharesModal(market: market, isYes: true),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
                  ),
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        BuySharesModal(market: market, isYes: false),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
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
                  ),
                ),
              ),
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

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MarketChart extends StatelessWidget {
  final bool isYesTrend;

  const _MarketChart({required this.isYesTrend});

  @override
  Widget build(BuildContext context) {
    final color = isYesTrend ? AppColors.success : AppColors.error;

    // Dummy Data
    final spots = [
      const FlSpot(0, 0.4),
      const FlSpot(1, 0.45),
      const FlSpot(2, 0.42),
      const FlSpot(3, 0.5),
      const FlSpot(4, 0.48),
      const FlSpot(5, 0.55),
      const FlSpot(6, 0.6),
      const FlSpot(7, 0.65),
      const FlSpot(8, 0.62),
      const FlSpot(9, 0.7),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 9,
        minY: 0.3,
        maxY: 0.8,
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
