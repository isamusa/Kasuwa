import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/providers/order_details_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/add_review_screen.dart'; // Import the review screen
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/opay_payment_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderDetailsProvider _provider;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _provider = OrderDetailsProvider(authProvider);
    // Fetch the latest details when the screen loads
    _provider.fetchOrderDetails(widget.orderId);
  }

  Future<void> _handleRetryPayment(
      BuildContext context, OrderDetailsProvider provider) async {
    final result = await provider.retryPayment();

    if (!context.mounted) return;

    if (result['success']) {
      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OpayPaymentScreen(checkoutUrl: result['url']!),
        ),
      );
      // After returning from the payment screen, refresh the order details.
      if (paymentResult == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment Successful! Updating order...'),
              backgroundColor: Colors.green),
        );
        await provider.fetchOrderDetails(widget.orderId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelivery(
      BuildContext context, OrderDetailsProvider provider) async {
    final success = await provider.confirmDelivery();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you for confirming!'),
            backgroundColor: Colors.green),
      );
      // No navigation here, the state will update the button automatically
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not confirm delivery. Please try again.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<OrderDetailsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Order Details'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: _buildBody(provider),
            bottomNavigationBar: _buildBottomBar(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(OrderDetailsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    if (provider.order == null) {
      return const Center(child: Text('Order not found.'));
    }
    return _buildContent(provider.order!);
  }

  // THE FIX: This widget now conditionally displays the correct button based on order status.
  Widget? _buildBottomBar(BuildContext context, OrderDetailsProvider provider) {
    if (provider.order == null) return null;

    final status = provider.order!.status.toLowerCase();
    final paymentStatus = provider.order!.paymentStatus.toLowerCase();

    // Condition 1: Show "Pay Now" button if payment is pending
    if (paymentStatus == 'pending_payment' && status != 'cancelled') {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: provider.isRetryingPayment
              ? null
              : () => _handleRetryPayment(context, provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: provider.isRetryingPayment
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : const Text('Pay Now', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // Condition 1: Show "Confirm Order Received" button
    if (['shipped', 'in_transit'].contains(status)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: provider.isConfirming
              ? null
              : () => _confirmDelivery(context, provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: provider.isConfirming
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : const Text('Confirm Order Received',
                  style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // Condition 2: Show "Write a Review" button
    if (status == 'delivered') {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                // Navigate to the review screen, passing the order details
                builder: (_) => AddReviewScreen(order: provider.order!),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.orange.shade800, // Different color for distinction
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Write a Review', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // For any other status (pending, processing, etc.), show no button.
    return null;
  }

  Widget _buildContent(OrderDetail order) {
    final subtotal = order.rawTotalAmount - order.rawShippingFee;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOrderSummaryHeader(order),
        const SizedBox(height: 24),
        _buildOrderStatusTracker(order.status),
        const SizedBox(height: 24),
        _buildSectionCard('Items Ordered', _buildItemsList(order.items)),
        const SizedBox(height: 16),
        _buildSectionCard(
            'Shipping Information', _buildShippingInfo(order.shippingAddress)),
        const SizedBox(height: 16),
        _buildSectionCard(
            'Payment Summary',
            _buildPaymentSummary(
                order.totalAmount, order.shippingFee, subtotal)),
      ],
    );
  }

  Widget _buildOrderSummaryHeader(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(order.orderNumber,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Placed on ${order.date}',
            style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildOrderStatusTracker(String currentStatus) {
    final statuses = [
      'Pending',
      'Processing',
      'Shipped',
      'In Transit',
      'Delivered',
      'Completed'
    ];
    int currentIndex = statuses
        .indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: Row(
            children: List.generate(statuses.length, (index) {
              final isCompleted = index <= currentIndex;
              final isLast = index == statuses.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCompleted ? Colors.green : Colors.grey[300],
                            border: Border.all(
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.grey[400]!),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statuses[index],
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Divider(
                            thickness: 2,
                            color:
                                isCompleted ? Colors.green : Colors.grey[300],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<OrderDetailItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error)),
                )),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Qty: ${item.quantity}'),
                ],
              ),
            ),
            Text(item.price),
          ],
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Widget _buildShippingInfo(ShippingAddressDetail address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address.recipientName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(address.fullAddress, style: TextStyle(color: Colors.grey[800])),
        const SizedBox(height: 4),
        Text(address.phoneNumber, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildPaymentSummary(
      String totalAmount, String shippingFee, double subTotal) {
    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Subtotal'), Text(subTotal.toString())]),
        const SizedBox(height: 8),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Shipping Fee'), Text(shippingFee)]),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(totalAmount,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor)),
          ],
        ),
      ],
    );
  }
}
