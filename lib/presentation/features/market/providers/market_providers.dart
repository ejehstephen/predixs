import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/market_repository_impl.dart';
import '../../../../domain/repositories/market_repository.dart';
import '../../../../domain/entities/market.dart';
export '../../../../domain/entities/market.dart';
import '../../../../domain/entities/market_price_point.dart';
export '../../../../domain/entities/market_price_point.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepositoryImpl(Supabase.instance.client);
});

final marketListProvider = FutureProvider<List<Market>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  final data = await repo.fetchMarkets();
  return data.map((json) => Market.fromJson(json)).toList();
});

final marketProvider = FutureProvider.family<Market, String>((ref, id) async {
  final repo = ref.watch(marketRepositoryProvider);
  final data = await repo.fetchMarketById(id);
  if (data == null) throw Exception('Market not found');
  return Market.fromJson(data);
});

final marketHistoryProvider =
    FutureProvider.family<List<MarketPricePoint>, String>((ref, id) async {
      final repo = ref.watch(marketRepositoryProvider);
      final data = await repo.fetchMarketHistory(id);
      return data.map((json) => MarketPricePoint.fromJson(json)).toList();
    });
