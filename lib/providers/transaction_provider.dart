import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  /// FILTER
  TransactionType? _filterType;
  String? _filterCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  /// ================= GETTERS =================
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ================= FILTERED =================
  List<Transaction> get filteredTransactions {
    var result = List<Transaction>.from(_transactions);

    if (_filterType != null) {
      result = result.where((t) => t.type == _filterType).toList();
    }

    if (_filterCategoryId != null) {
      result = result.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    if (_filterStartDate != null) {
      result =
          result.where((t) => t.date.isAfter(_filterStartDate!)).toList();
    }

    if (_filterEndDate != null) {
      result =
          result.where((t) => t.date.isBefore(_filterEndDate!)).toList();
    }

    return result;
  }

  /// ================= STATS =================
  int get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  int get balance => totalIncome - totalExpense;

  /// ================= LOAD =================
  Future<void> loadTransactions({
    String? walletId,
  }) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final data = await _transactionService.getTransactions(
        user.id,
        walletId: walletId,
      );

      /// 🔥 FIX: Map → Model
      _transactions =
          data.map((e) => Transaction.fromJson(e)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ================= ADD =================
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      // 1. Lưu giao dịch
      await _transactionService.addTransaction(
        userId: user.id,
        walletId: transaction.walletId,
        type: transaction.type.name, // enum → string
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        note: transaction.note,
        transactionDate: transaction.date,
      );

      // 2. Cập nhật số dư ví
      final walletData = await _walletService.getWalletById(transaction.walletId);
      if (walletData != null) {
        int currentBalance = (walletData['balance'] ?? 0) as int;
        int newBalance = transaction.type == TransactionType.income
            ? currentBalance + transaction.amount
            : currentBalance - transaction.amount;
        
        await _walletService.updateBalance(transaction.walletId, newBalance);
      }

      await loadTransactions();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= UPDATE =================
  Future<void> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      // 1. Lấy thông tin giao dịch cũ để hoàn tác số dư
      final oldData = _transactions.firstWhere((t) => t.id == transaction.id);
      
      // 2. Cập nhật giao dịch
      await _transactionService.updateTransaction(
        transaction.id,
        {
          'wallet_id': transaction.walletId,
          'type': transaction.type.name,
          'amount': transaction.amount,
          'category_id': transaction.categoryId,
          'note': transaction.note,
          'date': transaction.date.toIso8601String(),
        },
      );

      // 3. Cập nhật số dư ví
      final walletData = await _walletService.getWalletById(transaction.walletId);
      if (walletData != null) {
        int balance = (walletData['balance'] ?? 0) as int;
        
        // Hoàn tác số dư cũ
        balance = oldData.type == TransactionType.income
            ? balance - oldData.amount
            : balance + oldData.amount;
        
        // Áp dụng số dư mới
        balance = transaction.type == TransactionType.income
            ? balance + transaction.amount
            : balance - transaction.amount;
            
        await _walletService.updateBalance(transaction.walletId, balance);
      }

      await loadTransactions();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= DELETE =================
  Future<void> deleteTransaction(String transactionId) async {
    _setLoading(true);
    try {
      final transaction = _transactions.firstWhere((t) => t.id == transactionId);

      // 1. Xoá giao dịch
      await _transactionService.deleteTransaction(transactionId);

      // 2. Hoàn tác số dư ví
      final walletData = await _walletService.getWalletById(transaction.walletId);
      if (walletData != null) {
        int currentBalance = (walletData['balance'] ?? 0) as int;
        int newBalance = transaction.type == TransactionType.income
            ? currentBalance - transaction.amount
            : currentBalance + transaction.amount;
        
        await _walletService.updateBalance(transaction.walletId, newBalance);
      }

      _transactions.removeWhere((t) => t.id == transactionId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= FILTER =================
  void setFilter({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _filterType = type;
    _filterCategoryId = categoryId;
    _filterStartDate = startDate;
    _filterEndDate = endDate;

    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterCategoryId = null;
    _filterStartDate = null;
    _filterEndDate = null;

    notifyListeners();
  }

  /// ================= ERROR =================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ================= LOADING =================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
