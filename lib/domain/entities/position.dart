class Position {
  final String id;
  final String marketId;
  final String marketTitle;
  final String side; // 'Yes' or 'No'
  final double shares; // Changed to double as DB uses numeric
  final double avgPrice;
  final double currentPrice;
  final DateTime marketEndTime;
  final bool isMarketResolved;

  Position({
    required this.id,
    required this.marketId,
    required this.marketTitle,
    required this.side,
    required this.shares,
    required this.avgPrice,
    required this.currentPrice,
    required this.marketEndTime,
    required this.isMarketResolved,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    // Expecting join: { ..., markets: { title: "...", yes_price: 0.5, no_price: 0.5 } }
    final market = json['markets'];
    final marketTitle = market != null ? market['title'] : 'Unknown Market';
    final side = json['side'] as String;
    final shares = (json['shares'] as num).toDouble();
    final avgPrice = (json['avg_price'] as num).toDouble();

    final isYes = side == 'Yes';
    final currentPrice = isYes
        ? (market['yes_price'] as num).toDouble()
        : (market['no_price'] as num).toDouble();

    final endTime =
        DateTime.tryParse(market['end_date']?.toString() ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    final isResolved = (market['is_resolved'] as bool? ?? false);

    return Position(
      id: json['id'],
      marketId: json['market_id'],
      marketTitle: marketTitle,
      side: side,
      shares: shares,
      avgPrice: avgPrice,
      currentPrice: currentPrice,
      marketEndTime: endTime,
      isMarketResolved: isResolved,
    );
  }

  // Helpers for UI
  double get value => shares * currentPrice;
  double get invested => shares * avgPrice;
  double get pnl => value - invested;
  double get pnlPercent => invested == 0 ? 0 : (pnl / invested) * 100;
}
