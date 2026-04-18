import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  /// ================= GETTERS =================
  List<Category> get categories => _categories;

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == TransactionType.expense).toList();

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == TransactionType.income).toList();

  List<Category> get systemCategories =>
      _categories.where((c) => c.isSystem).toList();

  List<Category> get userCategories =>
      _categories.where((c) => !c.isSystem).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ================= LOAD =================
  Future<void> loadCategories() async {
    _setLoading(true);
    try {
      _categories = await _categoryService.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= ADD =================
  Future<void> addCategory(Category category) async {
    _setLoading(true);
    try {
      await _categoryService.createCategory(category);
      await loadCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= UPDATE =================
  Future<void> updateCategory(Category category) async {
    _setLoading(true);
    try {
      await _categoryService.updateCategory(category);
      await loadCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= DELETE =================
  Future<void> deleteCategory(String categoryId) async {
    _setLoading(true);
    try {
      await _categoryService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= FIND =================
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
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