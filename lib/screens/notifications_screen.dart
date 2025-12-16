import 'package:flutter/material.dart';
import 'package:kasuwa/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kasuwa/screens/order_details_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The screen consumes the globally available NotificationProvider.
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Mark All as Read',
                      style: TextStyle(color: Colors.white)),
                )
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _buildNotificationTile(context, notification, provider);
      },
      separatorBuilder: (context, index) =>
          const Divider(height: 0, indent: 16, endIndent: 16),
    );
  }

  Widget _buildNotificationTile(BuildContext context,
      AppNotification notification, NotificationProvider provider) {
    // Check if the notification was sent to a Shop model.
    final bool isShopNotification =
        notification.notifiableType.contains('Shop');

    return ListTile(
      tileColor: notification.isRead
          ? Colors.white
          : AppTheme.primaryColor.withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? Colors.grey[200]
            : AppTheme.primaryColor.withOpacity(0.2),
        child: Icon(
          isShopNotification
              ? Icons.storefront_outlined
              : Icons.receipt_long_outlined,
          color: notification.isRead ? Colors.grey[600] : AppTheme.primaryColor,
        ),
      ),
      title: Text(notification.title,
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(
            timeago.format(notification.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        // Mark as read when tapped
        provider.markAsRead(notification.id);

        // If it's an order notification, navigate to the order details
        if (notification.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsScreen(orderId: notification.orderId!),
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No Notifications Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Important updates and alerts will appear here.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
