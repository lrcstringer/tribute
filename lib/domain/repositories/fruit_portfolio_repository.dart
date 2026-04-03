import '../entities/fruit.dart';

abstract class FruitPortfolioRepository {
  Future<FruitPortfolio> loadPortfolio();
  Future<void> updateOnCompletion(List<FruitType> fruits);
  Future<void> updateHabitCount(List<FruitType> fruits, int delta);
  Future<void> resetPortfolio();
}
