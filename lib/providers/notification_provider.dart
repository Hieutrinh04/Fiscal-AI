import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  /// ================= GETTERS =================
  List<AppNotification> get notifications => _notifications;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ================= LOAD =================
  Future<void> loadNotifications() async {
    _setLoading(true);
    try {
      _notifications = await _notificationService.getNotifications();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// ================= MARK 1 =================
  Future<void> markAsRead(String id) async {
    // Optimistic: cập nhật UI ngay lập tức
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _notificationService.markAsRead(id);
    } catch (e) {
      // Không rollback - giữ UI đã đọc, chỉ log lỗi
      _error = e.toString();
    }
  }

  /// ================= MARK ALL =================
  Future<void> markAllAsRead() async {
    // Optimistic: cập nhật UI ngay lập tức
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      // Không rollback - giữ UI đã đọc, chỉ log lỗi
      _error = e.toString();
    }
  }

  /// ================= DELETE =================
  Future<void> deleteNotification(String id) async {
    // Optimistic: xoá khỏi UI ngay lập tức
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _notifications.removeAt(index);
    notifyListeners();

    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      // Không rollback - giữ UI đã xoá, chỉ log lỗi
      _error = e.toString();
    }
  }

  /// ================= CREATE =================
  Future<void> addNotification({
    required String title,
    String? body,
    String type = 'general',
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await _notificationService.addNotification(
        userId: user.id,
        title: title,
        body: body,
        type: type,
      );

      // Append vào list thay vì reload toàn bộ
      _notifications.insert(0, AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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