import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/portfolio_repository_impl.dart';
import '../../../../domain/entities/position.dart';
import '../../../../domain/repositories/portfolio_repository.dart';
import '../../wallet/providers/wallet_providers.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepositoryImpl(Supabase.instance.client);
});

final portfolioPositionsProvider = FutureProvider<List<Position>>((ref) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return await repo.fetchUserPositions();
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
