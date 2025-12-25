abstract class MarketRepository {
  /// Fetches all active markets.
  Future<List<Map<String, dynamic>>> fetchMarkets();

  /// Fetches a specific market by ID.
  Future<Map<String, dynamic>?> fetchMarketById(String marketId);

  /// Places a trade order.
  ///
  /// [marketId] The ID of the market.
  /// [outcome] 'yes' or 'no'.
  /// [amount] in NGN.
  /// Returns a JSON object with success status and shares info.
  Future<Map<String, dynamic>> placeTrade({
    required String marketId,
    required String outcome,
    required double amount,
  });

  /// Sells shares in a market.
  ///
  /// [marketId] The ID of the market.
  /// [outcome] 'Yes' or 'No'.
  /// [shares] Number of shares to sell.
  /// Returns a JSON object with success status and return amount.
  Future<Map<String, dynamic>> sellShares({
    required String marketId,
    required String outcome,
    required double shares,
  });

  /// Fetches price history for a market.
  Future<List<Map<String, dynamic>>> fetchMarketHistory(String marketId);

  /// Realtime stream of active markets.
  Stream<List<Map<String, dynamic>>> watchMarkets();
}
