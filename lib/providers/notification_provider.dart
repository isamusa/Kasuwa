import 'package:flutter/material.dart';
import 'package:kasuwa/services/notification_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';

// --- Data Model for a Notification ---
class AppNotification {
  final String id;
  final String title;
  final String message;
  final int? orderId;
  final DateTime createdAt;
  final bool isRead;
  final String notifiableType;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.orderId,
    required this.createdAt,
    required this.isRead,
    required this.notifiableType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // THE FIX: Safely handle the case where 'data' might be null or not a map.
    // We default to an empty map if 'data' is null or not the expected type.
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AppNotification(
      id: json['id'],
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? 'You have a new notification.',
      orderId: data['order_id'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['read_at'] != null,
      notifiableType: json['notifiable_type'] ?? '',
    );
  }
}

// --- The Provider Class ---
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
    print(token);
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

    final notificationIndex =
        _notifications.indexWhere((n) => n.id == notificationId);
    if (notificationIndex != -1 && !_notifications[notificationIndex].isRead) {
      final oldNotification = _notifications[notificationIndex];
      _notifications[notificationIndex] = AppNotification(
        id: oldNotification.id,
        title: oldNotification.title,
        message: oldNotification.message,
        orderId: oldNotification.orderId,
        createdAt: oldNotification.createdAt,
        isRead: true,
        notifiableType: oldNotification.notifiableType,
      );
      notifyListeners();

      await _notificationService.markAsRead(notificationId, token);
    }
  }

  Future<void> markAllAsRead() async {
    final token = _auth.token;
    if (token == null) return;

    _notifications = _notifications
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              orderId: n.orderId,
              createdAt: n.createdAt,
              isRead: true,
              notifiableType: n.notifiableType,
            ))
        .toList();
    notifyListeners();

    await _notificationService.markAllAsRead(token);
  }

  void _clearNotifications() {
    _notifications = [];
    _hasFetchedData = false;
    notifyListeners();
  }
}
