import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  final SupabaseClient _client;

  MarketRepositoryImpl(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchMarkets() async {
    try {
      final List<dynamic> response = await _client
          .from('markets')
          .select()
          .eq('is_resolved', false) // Filter out resolved markets
          .order('volume', ascending: false); // Show highest volume first
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch markets: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchMarketById(String marketId) async {
    try {
      final response = await _client
          .from('markets')
          .select()
          .eq('id', marketId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch market $marketId: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> placeTrade({
    required String marketId,
    required String outcome,
    required double amount,
  }) async {
    try {
      final response = await _client.rpc(
        'buy_shares',
        params: {
          'p_market_id': marketId,
          'p_outcome': outcome,
          'p_amount': amount,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Trade failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sellShares({
    required String marketId,
    required String outcome,
    required double shares,
  }) async {
    try {
      final response = await _client.rpc(
        'sell_shares',
        params: {
          'p_market_id': marketId,
          'p_outcome': outcome,
          'p_shares_to_sell': shares,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Sell failed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMarketHistory(String marketId) async {
    try {
      final List<dynamic> response = await _client
          .from('market_price_history')
          .select()
          .eq('market_id', marketId)
          .order('created_at', ascending: true);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      // Return empty if fail or no history
      print('Error fetching history: $e');
      return [];
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMarkets() {
    return _client
        .from('markets')
        .stream(primaryKey: ['id'])
        .order('volume', ascending: false)
        .map((data) => data.cast<Map<String, dynamic>>());
  }
}
