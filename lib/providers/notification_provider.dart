import 'package:flutter/material.dart';
import 'package:kasuwa/services/notification_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';
// 1. IMPORT THE MODEL
import 'package:kasuwa/models/notification_model.dart';

// 2. MAKE SURE 'class AppNotification' IS DELETED FROM HERE

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final AuthProvider _auth;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _hasFetchedData = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider(this._auth);

  void update(AuthProvider auth) {
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchNotifications();
    }
    if (!auth.isAuthenticated && _hasFetchedData) {
      _clearNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    final token = _auth.token;
    if (token == null) return;

    _isLoading = true;
    _hasFetchedData = true;
    notifyListeners();

    try {
      final notificationData =
          await _notificationService.getNotifications(token);
      _notifications = notificationData
          .map((data) => AppNotification.fromJson(data))
          .toList();
    } catch (e) {
      print("Error fetching notifications: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final token = _auth.token;
    if (token == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final old = _notifications[index];
      // Create copy with isRead = true
      _notifications[index] = AppNotification(
        id: old.id,
        title: old.title,
        message: old.message,
        type: old.type,
        notifiableType: old.notifiableType,
        createdAt: old.createdAt,
        isRead: true,
        orderId: old.orderId,
      );
      notifyListeners();

      await _notificationService.markAsRead(notificationId, token);
    }
  }

  Future<void> markAllAsRead() async {
    final token = _auth.token;
    if (token == null) return;

    _notifications = _notifications.map((n) {
      return AppNotification(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        notifiableType: n.notifiableType,
        createdAt: n.createdAt,
        isRead: true,
        orderId: n.orderId,
      );
    }).toList();
    notifyListeners();

    await _notificationService.markAllAsRead(token);
  }

  void _clearNotifications() {
    _notifications = [];
    _hasFetchedData = false;
    notifyListeners();
  }
}
