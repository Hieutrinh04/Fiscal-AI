import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => g.status == GoalStatus.active).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.status == GoalStatus.completed).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGoals() async {
    _setLoading(true);
    try {
      _goals = await _goalService.getGoals();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> addGoal(Goal goal) async {
    _setLoading(true);
    try {
      await _goalService.createGoal(goal);
      await loadGoals();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> updateGoal(Goal goal) async {
    _setLoading(true);
    try {
      await _goalService.updateGoal(goal);
      await loadGoals();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> addAmount(String goalId, int amount) async {
    _setLoading(true);
    try {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      final newAmount = goal.currentAmount + amount;
      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        status: newAmount >= goal.targetAmount ? GoalStatus.completed : goal.status,
      );
      await _goalService.updateGoal(updatedGoal);
      await loadGoals();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> deleteGoal(String goalId) async {
    _setLoading(true);
    try {
      await _goalService.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
