abstract class WalletRepository {
  /// Fetches the user's current wallet balance.
  Future<double> fetchBalance();

  /// Fetches the user's transaction history.
  Future<List<Map<String, dynamic>>> fetchTransactions();
}
