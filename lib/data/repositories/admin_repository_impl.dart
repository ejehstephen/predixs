import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final SupabaseClient _client;

  AdminRepositoryImpl(this._client);

  @override
  Future<double> fetchTotalRevenue() async {
    try {
      // In a real large-scale app, we'd use an RPC for this.
      // For now, we fetch 'fee' transactions.
      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('type', 'fee');

      final List<dynamic> data = response;
      double total = 0;
      for (var row in data) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching revenue: $e');
      return 0.0;
    }
  }
}
