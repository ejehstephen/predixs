import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/admin_repository_impl.dart';
import '../../../../domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(Supabase.instance.client);
});

final adminTotalRevenueProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchTotalRevenue();
});
