import 'package:flutter/material.dart';
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
    try {
      await _notificationService.markAsRead(id);

      final index =
          _notifications.indexWhere((n) => n.id == id);

      if (index != -1) {
        _notifications[index] =
            _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// ================= MARK ALL =================
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// ================= DELETE =================
  Future<void> deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);

      _notifications.removeWhere((n) => n.id == id);

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