import 'package:flutter/material.dart';
import 'package:kasuwa/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kasuwa/screens/order_details_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Notifications',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No notifications yet",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
          ],
        ),
      );
    }

    // Grouping Logic
    final grouped = <String, List<AppNotification>>{};
    for (var notif in provider.notifications) {
      final date = DateFormat('yyyy-MM-dd').format(notif.createdAt);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));

      String label = date;
      if (date == today)
        label = "Today";
      else if (date == yesterday) label = "Yesterday";

      if (!grouped.containsKey(label)) grouped[label] = [];
      grouped[label]!.add(notif);
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final notifications = grouped[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(key,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 13)),
            ),
            ...notifications
                .map((n) => _buildNotificationTile(context, n, provider))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context,
      AppNotification notification, NotificationProvider provider) {
    final isShop = notification.notifiableType.contains('Shop');
    Color bg = notification.isRead
        ? Colors.white
        : AppTheme.primaryColor.withOpacity(0.05);

    return InkWell(
      onTap: () {
        provider.markAsRead(notification.id);
        if (notification.orderId != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      OrderDetailsScreen(orderId: notification.orderId!)));
        }
      },
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isShop ? Colors.orange[50] : Colors.blue[50],
              child: Icon(
                isShop ? Icons.storefront : Icons.local_shipping_outlined,
                color: isShop ? Colors.orange : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 15)),
                      ),
                      Text(
                          timeago.format(notification.createdAt,
                              locale: 'en_short'),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
