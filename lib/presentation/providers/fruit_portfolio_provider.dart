import 'package:flutter/foundation.dart';
import '../../domain/entities/fruit.dart';
import '../../domain/repositories/fruit_portfolio_repository.dart';

class FruitPortfolioProvider extends ChangeNotifier {
  final FruitPortfolioRepository _repo;

  FruitPortfolioProvider(this._repo);

  FruitPortfolio? _portfolio;
  bool _isLoading = false;
  String? error;

  FruitPortfolio? get portfolio => _portfolio;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    error = null;
    notifyListeners();
    try {
      _portfolio = await _repo.loadPortfolio();
    } catch (e) {
      error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _repo.resetPortfolio();
    _portfolio = FruitPortfolio.empty();
    notifyListeners();
  }

  /// Called by HabitProvider after a successful habit check-in.
  Future<void> onHabitCompleted(List<FruitType> fruitTags) async {
    if (fruitTags.isEmpty) return;
    try {
      await _repo.updateOnCompletion(fruitTags);
      await load();
    } catch (_) {
      // Fire-and-forget — never surface portfolio update errors to the user.
    }
  }

  /// Called when a habit's fruit tags change (add/edit habit).
  /// [oldTags] are tags before the change, [newTags] after.
  Future<void> onHabitTagsChanged(
    List<FruitType> oldTags,
    List<FruitType> newTags,
  ) async {
    final added = newTags.where((f) => !oldTags.contains(f)).toList();
    final removed = oldTags.where((f) => !newTags.contains(f)).toList();

    try {
      if (added.isNotEmpty) await _repo.updateHabitCount(added, 1);
      if (removed.isNotEmpty) await _repo.updateHabitCount(removed, -1);
      if (added.isNotEmpty || removed.isNotEmpty) await load();
    } catch (_) {
      // Fire-and-forget.
    }
  }
}
