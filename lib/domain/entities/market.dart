import 'package:equatable/equatable.dart';

class Market extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime endTime;
  final String status; // 'open', 'closed', 'resolved'
  final double yesPrice;
  final double noPrice;
  final double yesShares;
  final double noShares;
  final double liquidityB;
  final double volume;
  final String? resolution;

  const Market({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.endTime,
    required this.status,
    required this.yesPrice,
    required this.noPrice,
    required this.yesShares,
    required this.noShares,
    required this.liquidityB,
    required this.volume,
    this.resolution,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      endTime:
          DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      status: (json['is_resolved'] as bool? ?? false) ? 'resolved' : 'open',
      yesPrice: (json['yes_price'] as num?)?.toDouble() ?? 0.5,
      noPrice: (json['no_price'] as num?)?.toDouble() ?? 0.5,
      yesShares: (json['yes_shares'] as num?)?.toDouble() ?? 0.0,
      noShares: (json['no_shares'] as num?)?.toDouble() ?? 0.0,
      liquidityB: (json['liquidity_b'] as num?)?.toDouble() ?? 100.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      resolution: json['resolution_outcome'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    endTime,
    status,
    yesPrice,
    noPrice,
    yesShares,
    noShares,
    liquidityB,
    volume,
    resolution,
  ];
}
