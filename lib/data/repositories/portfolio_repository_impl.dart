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
        final avgPrice = (row['average_buy_price'] as num).toDouble();

        final yesShares = (row['yes_shares'] as num).toDouble();
        final noShares = (row['no_shares'] as num).toDouble();

        // If user has YES shares
        if (yesShares > 0) {
          positions.add(
            Position(
              id: '${row['id']}_yes', // robust unique ID for UI
              marketId: row['market_id'],
              marketTitle: marketTitle,
              side: 'Yes',
              shares: yesShares,
              avgPrice:
                  avgPrice, // Note: Average price is aggregated in DB, implies mixed price if both sides held?
              // In a simple LMSR/Orderbook, usually one doesn't hold both, but if they do, avg_price might be same or specialized.
              // For MVP simpler to just use the row's avg.
              currentPrice: yesPrice,
            ),
          );
        }

        // If user has NO shares
        if (noShares > 0) {
          positions.add(
            Position(
              id: '${row['id']}_no',
              marketId: row['market_id'],
              marketTitle: marketTitle,
              side: 'No',
              shares: noShares,
              avgPrice: avgPrice,
              currentPrice: noPrice,
            ),
          );
        }
      }

      return positions;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching positions: $e');
      return [];
    }
  }
}
