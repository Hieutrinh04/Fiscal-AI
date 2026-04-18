import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  /// ================= GET =================
  Future<List<AppNotification>> getNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  /// ================= MARK 1 =================
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// ================= MARK ALL =================
  Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  /// ================= DELETE =================
  Future<void> deleteNotification(String id) async {
    await _client
        .from('notifications')
        .delete()
        .eq('id', id);
  }
}