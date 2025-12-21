import 'package:intl/intl.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String notifiableType;
  final DateTime createdAt;
  bool isRead;
  final int? orderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.notifiableType,
    required this.createdAt,
    required this.isRead,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Handle Laravel's 'data' field structure safely
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AppNotification(
      id: json['id'].toString(),
      title: data['title'] ?? json['title'] ?? 'Notification',
      message: data['message'] ?? json['message'] ?? '',
      type: json['type'] ?? 'general',
      notifiableType: json['notifiable_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['read_at'] != null,
      orderId: data['order_id'] is String
          ? int.tryParse(data['order_id'])
          : data['order_id'], // Handle string/int mismatch
    );
  }
}
