import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/wallet_repository_impl.dart';
import '../../../../domain/repositories/wallet_repository.dart';

class WalletTransaction {
  final String id;
  final String type; // 'deposit', 'withdraw', 'buy', 'sell'
  final double amount;
  final DateTime date;
  final String status; // 'completed', 'pending', 'failed'

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(Supabase.instance.client);
});

final walletBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.fetchBalance();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  final repo = ref.watch(walletRepositoryProvider);
  final data = await repo.fetchTransactions();
  return data.map((json) => WalletTransaction.fromJson(json)).toList();
});
