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
  final double initialLiquidity;
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
    required this.initialLiquidity,
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
      yesShares: 0.0, // Not tracked in markets table anymore
      noShares: 0.0, // Not tracked in markets table anymore
      initialLiquidity: 0.0,
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
    initialLiquidity,
    volume,
    resolution,
  ];
}
