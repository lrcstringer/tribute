import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class CircleHabitMilestoneProvider extends ChangeNotifier {
  final CircleRepository _repo;

  CircleHabitMilestoneProvider(this._repo);

  final Map<String, List<CircleHabitMilestone>> _byCircle = {};
  final Map<String, bool> _loading = {};
  String? error;

  List<CircleHabitMilestone> milestonesFor(String circleId) =>
      _byCircle[circleId] ?? [];

  bool isLoading(String circleId) => _loading[circleId] ?? false;

  Future<void> load(String circleId) async {
    if (_loading[circleId] == true) return;
    _loading[circleId] = true;
    error = null;
    notifyListeners();

    try {
      _byCircle[circleId] = await _repo.getCircleHabitMilestones(circleId);
    } catch (e) {
      error = e.toString();
    } finally {
      _loading[circleId] = false;
      notifyListeners();
    }
  }
}
