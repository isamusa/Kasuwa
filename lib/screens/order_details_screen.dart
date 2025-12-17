import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/providers/order_details_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/screens/cart_screen.dart';
import 'package:kasuwa/screens/add_review_screen.dart';
import 'package:kasuwa/screens/opay_payment_screen.dart';
import 'package:kasuwa/screens/payment_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';

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
    _provider.fetchOrderDetails(widget.orderId);
  }

  Future<void> _handleRetryPayment(BuildContext context) async {
    final result = await _provider.retryPayment();

    if (!context.mounted) return;

    if (result['success']) {
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OpayPaymentScreen(checkoutUrl: result['url']!),
        ),
      );

      if (paymentSuccess == true && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleReorder(BuildContext context, OrderDetail order) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Show loading
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()));

    // Add items to cart
    for (var item in order.items) {
      await cartProvider.addProductToCart(item.productId, item.quantity);
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    // Go to Cart
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<OrderDetailsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('Order Details',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.fetchOrderDetails(widget.orderId),
              child: _buildBody(provider),
            ),
            bottomNavigationBar: _buildBottomBar(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(OrderDetailsProvider provider) {
    if (provider.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (provider.error != null) return Center(child: Text(provider.error!));
    if (provider.order == null)
      return const Center(child: Text('Order not found.'));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildOrderHeader(provider.order!),
          const SizedBox(height: 20),
          _buildStatusStepper(provider.order!.status),
          const SizedBox(height: 20),
          _buildSection("Items Ordered", _buildItemsList(provider.order!)),
          const SizedBox(height: 16),
          _buildSection("Delivery Info", _buildShippingInfo(provider.order!)),
          const SizedBox(height: 16),
          _buildPaymentReceipt(provider.order!),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetail order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order #${order.orderNumber}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Placed on ${order.date}",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(order.paymentStatus.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildStatusStepper(String status) {
    final steps = ['pending', 'processing', 'shipped', 'delivered'];
    int activeIndex = steps.indexOf(status.toLowerCase());
    if (activeIndex == -1 && status == 'in_transit') activeIndex = 2;
    if (status == 'cancelled') return _buildCancelledStatus();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index <= activeIndex;
          return Expanded(
            child: Column(
              children: [
                Icon(_getStatusIcon(steps[index]),
                    color: isActive ? Colors.green : Colors.grey[300],
                    size: 24),
                const SizedBox(height: 4),
                Text(steps[index].capitalize(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.black : Colors.grey,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal))
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 12),
          Text("This order was cancelled",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.receipt_long;
      case 'processing':
        return Icons.inventory_2;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: content,
        ),
      ],
    );
  }

  Widget _buildItemsList(OrderDetail order) {
    return Column(
      children: order.items.map((item) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) =>
                      Container(color: Colors.grey[200], height: 60, width: 60),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("Qty: ${item.quantity}  x  ${item.price}",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShippingInfo(OrderDetail order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shippingAddress.recipientName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(order.shippingAddress.fullAddress,
                    style: TextStyle(color: Colors.grey[700], height: 1.4)),
                const SizedBox(height: 4),
                Text(order.shippingAddress.phoneNumber,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReceipt(OrderDetail order) {
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    return _buildSection(
        "Payment Summary",
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _row("Subtotal", currency.format(order.subtotal)),
              const SizedBox(height: 12),
              _row("Shipping Fee", order.shippingFee),
              const SizedBox(height: 16),
              const Divider(
                  color: Colors.grey,
                  thickness: 1.0), // You can implement a custom dashed divider
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Paid",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(order.totalAmount,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor)),
                ],
              )
            ],
          ),
        ));
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget? _buildBottomBar(BuildContext context, OrderDetailsProvider provider) {
    if (provider.order == null) return null;
    final status = provider.order!.status.toLowerCase();
    final payment = provider.order!.paymentStatus.toLowerCase();

    // 1. RE-ORDER (Cancelled)
    if (status == 'cancelled') {
      return _bottomBtn(
        label: "Re-order Items",
        icon: Icons.refresh,
        color: Colors.black87,
        onPressed: () => _handleReorder(context, provider.order!),
      );
    }

    // 2. PAY NOW (Pending)
    if (payment == 'pending_payment') {
      return _bottomBtn(
        label: "Complete Payment",
        icon: Icons.lock,
        color: AppTheme.primaryColor,
        isLoading: provider.isRetryingPayment,
        onPressed: () => _handleRetryPayment(context),
      );
    }

    // 3. CONFIRM DELIVERY (Shipped)
    if (['shipped', 'in_transit'].contains(status)) {
      return _bottomBtn(
        label: "Confirm Received",
        icon: Icons.check_circle_outline,
        color: Colors.green[700]!,
        isLoading: provider.isConfirming,
        onPressed: () => provider.confirmDelivery(),
      );
    }

    // 4. REVIEW (Delivered)
    if (status == 'delivered') {
      return _bottomBtn(
        label: "Write Review",
        icon: Icons.star_rate_rounded,
        color: Colors.amber[800]!,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddReviewScreen(order: provider.order!))),
      );
    }

    return null;
  }

  Widget _bottomBtn(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed,
      bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox() : Icon(icon, color: Colors.white),
          label: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
