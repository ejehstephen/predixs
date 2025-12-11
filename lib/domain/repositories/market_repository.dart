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
}
