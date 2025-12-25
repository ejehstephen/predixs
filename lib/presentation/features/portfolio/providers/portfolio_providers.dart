import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:predixs/presentation/features/market/providers/market_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/portfolio_repository_impl.dart';
import '../../../../domain/entities/position.dart';
import '../../../../domain/repositories/portfolio_repository.dart';
import '../../wallet/providers/wallet_providers.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepositoryImpl(Supabase.instance.client);
});

final rawPositionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.watchUserPositions();
});

// Computed provider that joins Positions with Market Data
final portfolioPositionsProvider = Provider<AsyncValue<List<Position>>>((ref) {
  final positionsAsync = ref.watch(rawPositionsProvider);
  final marketsAsync = ref.watch(marketListProvider);

  return positionsAsync.when(
    data: (rawPositions) {
      return marketsAsync.when(
        data: (markets) {
          final List<Position> positions = [];

          for (final row in rawPositions) {
            final marketId = row['market_id'];
            // Find market in cached list
            final market = markets.firstWhere(
              (m) => m.id == marketId,
              orElse: () => Market(
                id: 'unknown',
                title: 'Unknown',
                category: '',
                endTime: DateTime.now(),
                status: 'closed',
                liquidityB: 0,
                yesShares: 0,
                noShares: 0,
                yesPrice: 0,
                noPrice: 0,
                volume: 0,
                rules: '',
              ), // Dummy
            );

            if (market.id == 'unknown') continue;

            final side = row['side'] as String;
            final shares = (row['shares'] as num).toDouble();
            final avgPrice = (row['avg_price'] as num).toDouble();

            if (shares <= 0) continue;

            positions.add(
              Position(
                id: row['id'],
                marketId: market.id,
                marketTitle: market.title,
                side: side,
                shares: shares,
                avgPrice: avgPrice,
                currentPrice: side == 'Yes' ? market.yesPrice : market.noPrice,
              ),
            );
          }
          return AsyncValue.data(positions);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final portfolioInvestedProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final positions = ref.watch(portfolioPositionsProvider);
  return positions.whenData(
    (list) => list.fold(0.0, (sum, p) => sum + p.invested),
  );
});

final portfolioCurrentValueProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final positions = ref.watch(portfolioPositionsProvider);
  return positions.whenData(
    (list) => list.fold(0.0, (sum, p) => sum + p.value),
  );
});

final totalPortfolioValueProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final walletBalance = ref.watch(walletBalanceProvider);
  final portfolioValue = ref.watch(portfolioCurrentValueProvider);

  return walletBalance.when(
    data: (cash) => portfolioValue.when(
      data: (invested) => AsyncValue.data(cash + invested),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
