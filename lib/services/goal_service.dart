import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal.dart';

class GoalService {
  final _client = Supabase.instance.client;

  /// 🔥 GET GOALS
  Future<List<Goal>> getGoals() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('goals')
        .select()
        .eq('user_id', userId);

    return (data as List)
        .map((e) => Goal.fromJson(e))
        .toList();
  }

  /// 🔥 CREATE
  Future<void> createGoal(Goal goal) async {
    await _client.from('goals').insert(goal.toJson());
  }

  /// 🔥 UPDATE
  Future<void> updateGoal(Goal goal) async {
    await _client
        .from('goals')
        .update(goal.toJson())
        .eq('id', goal.id);
  }

  /// 🔥 DELETE
  Future<void> deleteGoal(String goalId) async {
    await _client
        .from('goals')
        .delete()
        .eq('id', goalId);
  }
}