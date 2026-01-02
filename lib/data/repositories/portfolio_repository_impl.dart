import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/position.dart';
import '../../domain/repositories/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepositoryImpl(this._client);

  @override
  Future<List<Position>> fetchUserPositions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('positions')
          .select('*, markets(*)')
          .eq('user_id', userId);

      final List<Position> positions = [];

      for (final row in response) {
        final market = row['markets'];
        if (market == null) continue;

        final marketTitle = market['title'] ?? 'Unknown Market';
        final yesPrice = (market['yes_price'] as num).toDouble();
        final noPrice = (market['no_price'] as num).toDouble();

        // Parse DB columns
        final side = row['side'] as String; // 'Yes' or 'No'
        final shares = (row['shares'] as num).toDouble();
        final avgPrice = (row['avg_price'] as num).toDouble();
        final endTime =
            DateTime.tryParse(market['end_date']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 1));
        final isResolved = (market['is_resolved'] as bool? ?? false);

        if (shares <= 0) continue;

        positions.add(
          Position(
            id: row['id'],
            marketId: row['market_id'],
            marketTitle: marketTitle,
            side: side,
            shares: shares,
            avgPrice: avgPrice,
            // Determine current market price based on side held
            currentPrice: side == 'Yes' ? yesPrice : noPrice,
            marketEndTime: endTime,
            isMarketResolved: isResolved,
          ),
        );
      }

      return positions;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching positions: $e');
      return [];
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchUserPositions() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('positions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.cast<Map<String, dynamic>>());
  }
}
