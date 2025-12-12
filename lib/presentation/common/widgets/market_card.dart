import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/market.dart';

class MarketCard extends StatelessWidget {
  final Market market;
  final VoidCallback? onTap;

  const MarketCard({super.key, required this.market, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(market.category),
                      color: AppColors.primary,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Text(
                          'Ends ${_formatDate(market.endTime)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              // Prices
              Row(
                children: [
                  Expanded(
                    child: _PriceButton(
                      label: 'Yes',
                      price: market.yesPrice,
                      color: AppColors.yes,
                      onTap: () {}, // TODO: Quick buy?
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _PriceButton(
                      label: 'No',
                      price: market.noPrice,
                      color: AppColors.no,
                      onTap: () {}, // TODO: Quick buy?
                    ),
                  ),
                ],
              ),
              const Gap(12),
              // Volume or pool info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vol: ₦${market.volume.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  Icon(Icons.show_chart, size: 16, color: AppColors.success),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'crypto':
        return Icons.currency_bitcoin;
      case 'politics':
        return Icons.account_balance;
      case 'pop':
        return Icons.movie;
      default:
        return Icons.trending_up;
    }
  }

  String _formatDate(DateTime date) {
    // Simple date formatter, can use intl later
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PriceButton extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  final VoidCallback onTap;

  const _PriceButton({
    required this.label,
    required this.price,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            '₦${(price * 100).toStringAsFixed(1)}', // Display as rough NGN implied price or %
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
