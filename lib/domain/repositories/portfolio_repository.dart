import '../entities/position.dart';

abstract class PortfolioRepository {
  Future<List<Position>> fetchUserPositions();

  /// Realtime stream of user positions (raw data).
  Stream<List<Map<String, dynamic>>> watchUserPositions();
}
