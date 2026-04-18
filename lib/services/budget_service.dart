import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget.dart';

class BudgetService {
  final _client = Supabase.instance.client;

  /// ================= GET =================
  Future<List<Budget>> getBudgets({
    required int month,
    required int year,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final data = await _client
        .from('budgets')
        .select()
        .eq('user_id', user.id)
        .eq('month', month)
        .eq('year', year)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => Budget.fromJson(e))
        .toList();
  }

  /// ================= CREATE =================
  Future<void> createBudget(Budget budget) async {
    await _client.from('budgets').insert({
      ...budget.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// ================= UPDATE =================
  Future<void> updateBudget(Budget budget) async {
    await _client
        .from('budgets')
        .update({
          ...budget.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', budget.id);
  }

  /// ================= DELETE =================
  Future<void> deleteBudget(String budgetId) async {
    await _client
        .from('budgets')
        .delete()
        .eq('id', budgetId);
  }
}