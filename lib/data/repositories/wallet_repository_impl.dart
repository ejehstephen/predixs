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

  @override
  Future<void> deposit(double amount) async {
    try {
      await _client.rpc('deposit_funds', params: {'p_amount': amount});
    } catch (e) {
      throw Exception('Failed to deposit: $e');
    }
  }

  @override
  Future<void> withdraw(double amount) async {
    try {
      await _client.rpc('withdraw_funds', params: {'p_amount': amount});
    } catch (e) {
      throw Exception('Failed to withdraw: $e');
    }
  }

  @override
  Stream<double> watchBalance() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0.0);

    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return 0.0;
          return (data.first['balance'] as num).toDouble();
        });
  }
}
