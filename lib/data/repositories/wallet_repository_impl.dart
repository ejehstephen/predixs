import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _client;

  WalletRepositoryImpl(this._client);

  @override
  Future<double> fetchBalance() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await _client
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return 0.0;
      return (response['balance'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to fetch balance: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
