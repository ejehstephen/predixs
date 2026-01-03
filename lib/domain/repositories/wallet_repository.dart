abstract class WalletRepository {
  /// Fetches the user's current wallet balance.
  Future<double> fetchBalance();

  /// Fetches the user's transaction history.
  Future<List<Map<String, dynamic>>> fetchTransactions();

  /// Simulates a deposit (calls RPC).
  Future<void> deposit(double amount);

  /// Simulates a withdrawal (calls RPC).
  Future<void> withdraw(
    double amount, {
    required String bankName,
    required String accountNumber,
    required String accountName,
  });

  /// Realtime stream of wallet balance.
  Stream<double> watchBalance();
}
