class Position {
  final String id;
  final String marketId;
  final String marketTitle;
  final String side; // 'Yes' or 'No'
  final double shares; // Changed to double as DB uses numeric
  final double avgPrice;
  final double currentPrice;

  Position({
    required this.id,
    required this.marketId,
    required this.marketTitle,
    required this.side,
    required this.shares,
    required this.avgPrice,
    required this.currentPrice,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    // Expecting join: { ..., markets: { title: "...", yes_price: 0.5, no_price: 0.5 } }
    final market = json['markets'];
    final marketTitle = market != null ? market['title'] : 'Unknown Market';

    // Determine side and prices based on which shares > 0.
    // Logic: If yes_shares > 0, it's a YES position.
    // If both > 0, we might need 2 position objects or logic to handle split.
    // Ideally, for MVP, we might treat them as separate list items or dominant one.
    // Let's assume for now a row represents a "position" but the DB structure has both cols.
    // We'll parse checks here.

    final yesShares = (json['yes_shares'] as num).toDouble();
    final noShares = (json['no_shares'] as num).toDouble();

    // Simple heuristic: Return the side with shares. If both (which shouldn't happen in simple buy), pick YES?
    // Actually, distinct positions for YES and NO in same market are possible in theory but rare in this MVP flow.
    // Let's implement a static list extractor instead of single factory if needed,
    // but for now, let's just make it handle the primary non-zero side.

    bool isYes = yesShares > noShares;

    return Position(
      id: json['id'],
      marketId: json['market_id'],
      marketTitle: marketTitle,
      side: isYes ? 'Yes' : 'No',
      shares: isYes ? yesShares : noShares,
      avgPrice: (json['average_buy_price'] as num)
          .toDouble(), // This tracks avg entry
      currentPrice: isYes
          ? (market['yes_price'] as num).toDouble()
          : (market['no_price'] as num).toDouble(),
    );
  }

  // Helpers for UI
  double get value => shares * currentPrice;
  double get invested => shares * avgPrice;
  double get pnl => value - invested;
  double get pnlPercent => invested == 0 ? 0 : (pnl / invested) * 100;
}
