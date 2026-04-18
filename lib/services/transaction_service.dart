import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final _client = Supabase.instance.client;
  final String _table = 'transactions';
  final String _dateColumn = 'date';

  /// ================= GET =================
  Future<List<Map<String, dynamic>>> getTransactions(
    String userId, {
    String? type,
    String? categoryId,
    String? walletId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from(_table)
        .select('*, categories(id, user_id, name, icon, color, type, is_system, created_at)')
        .eq('user_id', userId);

    if (type != null) query = query.eq('type', type);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (walletId != null) query = query.eq('wallet_id', walletId);

    if (fromDate != null) {
      query = query.gte(
        _dateColumn,
        fromDate.toIso8601String(),
      );
    }

    if (toDate != null) {
      query = query.lte(
        _dateColumn,
        toDate.toIso8601String(),
      );
    }

    final data = await query
        .order(_dateColumn, ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  /// ================= RECENT =================
  Future<List<Map<String, dynamic>>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    return getTransactions(userId, limit: limit);
  }

  /// ================= CREATE =================
  Future<void> addTransaction({
    required String userId,
    required String walletId,
    required String type,
    required int amount,
    String? categoryId,
    String? note,
    DateTime? transactionDate,
  }) async {
    await _client.from(_table).insert({
      'user_id': userId,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'note': note,
      _dateColumn: (transactionDate ?? DateTime.now()).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// ================= UPDATE =================
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    await _client.from(_table).update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);
  }

  /// ================= DELETE =================
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from(_table).delete().eq('id', transactionId);
  }

  /// ================= TOTAL EXPENSE =================
  Future<int> getTotalExpense(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from(_table)
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('transaction_date', from.toIso8601String())
        .lte('transaction_date', to.toIso8601String());

    return (data as List).fold<int>(
      0,
      (sum, item) => sum + ((item['amount'] ?? 0) as int),
    );
  }

  /// ================= TOTAL INCOME =================
  Future<int> getTotalIncome(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from(_table)
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'income')
        .gte('transaction_date', from.toIso8601String())
        .lte('transaction_date', to.toIso8601String());

    return (data as List).fold<int>(
      0,
      (sum, item) => sum + ((item['amount'] ?? 0) as int),
    );
  }

  /// ================= GROUP BY CATEGORY =================
  Future<List<Map<String, dynamic>>> getExpenseByCategory(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from(_table)
        .select('amount, categories(name, icon, color)')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('transaction_date', from.toIso8601String())
        .lte('transaction_date', to.toIso8601String());

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in data) {
      final cat = item['categories'];

      final catName = cat?['name'] ?? 'Khác';

      if (grouped.containsKey(catName)) {
        grouped[catName]!['amount'] =
            (grouped[catName]!['amount'] as int) +
                ((item['amount'] ?? 0) as int);
      } else {
        grouped[catName] = {
          'name': catName,
          'icon': cat?['icon'],
          'color': cat?['color'],
          'amount': (item['amount'] ?? 0) as int,
        };
      }
    }

    final result = grouped.values.toList();

    result.sort(
      (a, b) =>
          (b['amount'] as int).compareTo(a['amount'] as int),
    );

    return result;
  }
}
