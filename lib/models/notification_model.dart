class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  bool isRead;
  final int? orderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'general',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['read_at'] != null,
      orderId: json['order_id'],
    );
  }
}
