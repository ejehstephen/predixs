import '../entities/position.dart';

abstract class PortfolioRepository {
  Future<List<Position>> fetchUserPositions();
}
