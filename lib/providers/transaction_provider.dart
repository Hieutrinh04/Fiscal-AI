import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  NotificationProvider? _notificationProvider;
  SettingsProvider? _settingsProvider;
  RealtimeChannel? _realtimeChannel;

  /// Gán NotificationProvider từ bên ngoài (qua MultiProvider)
  void setNotificationProvider(NotificationProvider np) {
    _notificationProvider = np;
  }

  /// Gán SettingsProvider từ bên ngoài
  void setSettingsProvider(SettingsProvider sp) {
    _settingsProvider = sp;
  }

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

  /// Lọc giao dịch theo loại (chi tiêu / thu nhập)
  List<Transaction> transactionsByType(TransactionType type) =>
      _transactions.where((t) => t.type == type).toList();

  /// Tổng tiền theo ngày cho 1 loại giao dịch
  /// Key: 'yyyy-MM-dd', Value: tổng amount
  Map<String, int> dailyTotals(TransactionType type) {
    final map = <String, int>{};
    for (final t in _transactions.where((t) => t.type == type)) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + t.amount;
    }
    return map;
  }

  /// Tổng tiền theo danh mục cho 1 loại giao dịch
  /// Key: categoryId (hoặc 'other'), Value: tổng amount
  Map<String, int> categoryTotals(TransactionType type) {
    final map = <String, int>{};
    for (final t in _transactions.where((t) => t.type == type)) {
      final catId = t.categoryId ?? 'other';
      map[catId] = (map[catId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Tổng tiền theo tháng (6 tháng gần nhất) cho 1 loại giao dịch
  /// Key: 'yyyy-MM', Value: tổng amount
  Map<String, int> monthlyTotals(TransactionType type, {int months = 6}) {
    final now = DateTime.now();
    final map = <String, int>{};
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      map[key] = 0;
    }
    for (final t in _transactions.where((t) => t.type == type)) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      if (map.containsKey(key)) {
        map[key] = map[key]! + t.amount;
      }
    }
    return map;
  }

  /// Giao dịch trong 1 ngày cụ thể theo loại
  List<Transaction> transactionsForDay(DateTime date, TransactionType type) {
    return _transactions.where((t) {
      return t.type == type &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
  }

  /// ================= REALTIME =================
  void subscribeRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('transactions-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => loadTransactions(),
        )
        .subscribe();
  }

  void cancelRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  @override
  void dispose() {
    cancelRealtime();
    super.dispose();
  }

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
      int? newBalance;
      final walletData = await _walletService.getWalletById(transaction.walletId);
      if (walletData != null) {
        int currentBalance = (walletData['balance'] ?? 0) as int;
        newBalance = transaction.type == TransactionType.income
            ? currentBalance + transaction.amount
            : currentBalance - transaction.amount;
        
        await _walletService.updateBalance(transaction.walletId, newBalance);
      }

      await loadTransactions();

      // Kiểm tra và gửi thông báo nếu cần
      await _checkAndNotifyAfterTransaction(transaction, newBalance);

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
      int? finalBalance;
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
            
        finalBalance = balance;
        await _walletService.updateBalance(transaction.walletId, balance);
      }

      await loadTransactions();

      // Kiểm tra và gửi thông báo nếu cần
      await _checkAndNotifyAfterTransaction(transaction, finalBalance);

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

  /// Cập nhật giao dịch chỉ với các field thay đổi (không cần tạo Transaction object)
  Future<void> updateTransactionFields(
    String transactionId, {
    TransactionType? type,
    int? amount,
    String? note,
  }) async {
    final old = _transactions.firstWhere((t) => t.id == transactionId);
    final updated = old.copyWith(
      type: type ?? old.type,
      amount: amount ?? old.amount,
      note: note ?? old.note,
    );
    await updateTransaction(updated);
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

  /// ================= NOTIFICATION TRIGGERS =================
  /// Kiểm tra điều kiện và gửi thông báo tự động sau giao dịch
  Future<void> _checkAndNotifyAfterTransaction(
    Transaction transaction,
    int? newBalance,
  ) async {
    final np = _notificationProvider;
    final sp = _settingsProvider;
    if (np == null || sp == null || !sp.notificationEnabled) return;

    // Chỉ kiểm tra cho chi tiêu
    if (transaction.type == TransactionType.expense) {
      final amountStr = Formatters.currency(transaction.amount.toDouble());

      // 1. Số dư âm (vượt quá số dư)
      if (newBalance != null && newBalance < 0) {
        await np.addNotification(
          title: '⚠️ Cảnh báo: Số dư âm!',
          body: 'Giao dịch $amountStr khiến số dư ví bị âm (${Formatters.currency(newBalance.toDouble())}). Hãy kiểm tra lại!',
          type: 'warning',
        );
      }

      // 2. Số dư rất thấp (< 50.000₫)
      if (newBalance != null && newBalance >= 0 && newBalance < 50000) {
        await np.addNotification(
          title: '💰 Số dư rất thấp',
          body: 'Số dư ví chỉ còn ${Formatters.currency(newBalance.toDouble())}. Hãy hạn chế chi tiêu!',
          type: 'warning',
        );
      }

      // 3. Chi tiêu lớn (> 500.000₫)
      if (transaction.amount >= 500000) {
        await np.addNotification(
          title: '💸 Chi tiêu lớn',
          body: 'Bạn vừa chi $amountStr. Đảm bảo điều này nằm trong kế hoạch của bạn!',
          type: 'warning',
        );
      }

      // 4. Chi tiêu trong ngày vượt 1.000.000₫
      final todayKey =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final dailyMap = dailyTotals(TransactionType.expense);
      final todayTotal = dailyMap[todayKey] ?? 0;
      if (todayTotal >= 1000000) {
        await np.addNotification(
          title: '📊 Chi tiêu hôm nay đã vượt 1 triệu',
          body: 'Tổng chi tiêu hôm nay: ${Formatters.currency(todayTotal.toDouble())}. Hãy cẩn thận!',
          type: 'warning',
        );
      }
    }

    // Thu nhập lớn
    if (transaction.type == TransactionType.income && transaction.amount >= 1000000) {
      final amountStr = Formatters.currency(transaction.amount.toDouble());
      await np.addNotification(
        title: '🎉 Thu nhập lớn',
        body: 'Bạn vừa nhận $amountStr. Tuyệt vời!',
        type: 'success',
      );
    }
  }
}
