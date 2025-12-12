import 'package:equatable/equatable.dart';

class MarketPricePoint extends Equatable {
  final DateTime timestamp;
  final double yesPrice;
  final double noPrice;

  const MarketPricePoint({
    required this.timestamp,
    required this.yesPrice,
    required this.noPrice,
  });

  factory MarketPricePoint.fromJson(Map<String, dynamic> json) {
    return MarketPricePoint(
      timestamp: DateTime.parse(json['created_at']),
      yesPrice: (json['yes_price'] as num).toDouble(),
      noPrice: (json['no_price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [timestamp, yesPrice, noPrice];
}
