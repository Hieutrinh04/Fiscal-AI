import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 🔥 OVER BUDGET
  List<Budget> get overBudgetList =>
      _budgets.where((b) => b.isOverBudget).toList();

  int get totalBudget =>
      _budgets.fold(0, (sum, b) => sum + b.amount);

  int get totalSpent =>
      _budgets.fold(0, (sum, b) => sum + b.spent);

  /// ================= LOAD =================
  Future<void> loadBudgets({int? month, int? year}) async {
    _setLoading(true);
    try {
      final now = DateTime.now();

      _budgets = await _budgetService.getBudgets(
        month: month ?? now.month,
        year: year ?? now.year,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= ADD =================
  Future<void> addBudget(Budget budget) async {
    _setLoading(true);
    try {
      await _budgetService.createBudget(budget);

      await loadBudgets(
        month: budget.month,
        year: budget.year,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= UPDATE =================
  Future<void> updateBudget(Budget budget) async {
    _setLoading(true);
    try {
      await _budgetService.updateBudget(budget);

      await loadBudgets(
        month: budget.month,
        year: budget.year,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= DELETE =================
  Future<void> deleteBudget(String budgetId) async {
    _setLoading(true);
    try {
      await _budgetService.deleteBudget(budgetId);

      _budgets.removeWhere((b) => b.id == budgetId);

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= ERROR =================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}