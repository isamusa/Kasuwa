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
import 'package:kasuwa/screens/return_request_screen.dart';

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
    // Fetch data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.fetchOrderDetails(widget.orderId);
    });
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

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()));

    for (var item in order.items) {
      await cartProvider.addProductToCart(item.productId, item.quantity);
    }

    if (!mounted) return;
    Navigator.pop(context);

    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  Future<void> _handleCancelOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text(
            "Are you sure you want to cancel this order? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("No, Keep it")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Yes, Cancel",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await _provider.cancelOrder(widget.orderId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Order cancelled successfully"),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to cancel order. Please try again."),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- NEW: Handle Return Request ---
  Future<void> _handleReturnRequest(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Request Return"),
          ],
        ),
        content:
            const Text("You are about to request a return for this order. \n\n"
                "• Returns are only valid for defective items.\n"
                "• This request must be made within 12 hours of delivery.\n\n"
                "Do you want to proceed?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReturnRequestScreen(orderId: widget.orderId),
                    ),
                  ),
              child: const Text("Proceed",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // TODO: Call your Provider API here
      // final success = await _provider.requestReturn(widget.orderId);

      // Simulating API call for UI demonstration
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Return request submitted. Support will contact you."),
            backgroundColor: AppTheme.successColor));
      }
    }
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
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) return Center(child: Text(provider.error!));
    if (provider.order == null) {
      return const Center(child: Text('Order not found.'));
    }

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
    Color headerColor = AppTheme.primaryColor;
    if (order.status == 'cancelled') headerColor = Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: headerColor.withOpacity(0.3),
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
    final lowerStatus = status.toLowerCase();

    // 1. Handle Cancelled
    if (lowerStatus == 'cancelled') {
      return _buildCancelledStatus();
    }

    // 2. Handle Completed/Delivered (NEW: Show Banner instead of icons)
    if (lowerStatus == 'delivered' || lowerStatus == 'completed') {
      return _buildCompletedBanner();
    }

    // 3. Handle Active Tracking (Stepper)
    final steps = ['pending', 'processing', 'shipped', 'delivered'];
    int activeIndex = steps.indexOf(lowerStatus);

    // Map 'in_transit' to 'shipped' step visually if needed
    if (activeIndex == -1 && lowerStatus == 'in_transit') activeIndex = 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index <= activeIndex;
          // Don't show the last 'delivered' icon in the stepper if we are not there yet
          // (Optional: standard steppers show all steps, just greyed out. We keep it standard.)
          return Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(steps[index]),
                      color: isActive ? Colors.green : Colors.grey[300],
                      size: 20),
                ),
                const SizedBox(height: 8),
                Text(steps[index].capitalize(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.black87 : Colors.grey,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal))
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- NEW: Completion Banner Widget ---
  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50, // Light green background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle,
                color: Colors.green.shade600, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Completed",
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This order has been delivered successfully. Thank you for shopping with us!",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              const Divider(color: Colors.grey, thickness: 1.0),
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

  // --- UPDATED BOTTOM BAR ---
  Widget? _buildBottomBar(BuildContext context, OrderDetailsProvider provider) {
    if (provider.order == null) return null;
    final status = provider.order!.status.toLowerCase();
    final payment = provider.order!.paymentStatus.toLowerCase();

    // 1. CANCELLED / RE-ORDER
    if (status == 'cancelled') {
      return _buildBottomContainer(
        child: _bottomBtn(
          label: "Re-order Items",
          icon: Icons.refresh,
          color: Colors.black87,
          onPressed: () => _handleReorder(context, provider.order!),
        ),
      );
    }

    // 2. PAY NOW / CANCEL (Unpaid)
    if (payment == 'pending_payment' || payment == 'unpaid') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isRetryingPayment
                      ? null
                      : () => _handleRetryPayment(context),
                  icon: provider.isRetryingPayment
                      ? const SizedBox()
                      : const Icon(Icons.lock, color: Colors.white),
                  label: provider.isRetryingPayment
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Complete Payment",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCancelOrder(context),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text("Cancel Order",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. CONFIRM DELIVERY
    if (['shipped', 'in_transit'].contains(status)) {
      return _buildBottomContainer(
        child: _bottomBtn(
          label: "Confirm Received",
          icon: Icons.check_circle_outline,
          color: Colors.green[700]!,
          isLoading: provider.isConfirming,
          onPressed: () => provider.confirmDelivery(),
        ),
      );
    }

    // 4. REVIEW + RETURN (Delivered)
    if (status == 'delivered') {
      // 12-Hour Return Logic
      // IMPORTANT: Ensure your backend sends 'updated_at' or 'delivered_at' in the Order model.
      // If not available, this logic defaults to "Always Allow" or "Never Allow" depending on default.

      // Fallback: Use current time if date is missing (Safe Default)
      final deliveryDate =
          DateTime.tryParse(provider.order!.date) ?? DateTime.now();
      // NOTE: Replace 'provider.order!.date' with 'provider.order!.updatedAt' if available from backend.

      final hoursSinceDelivery =
          DateTime.now().difference(deliveryDate).inHours;
      final canReturn = hoursSinceDelivery <= 12;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary Action: Review
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddReviewScreen(order: provider.order!))),
                  icon:
                      const Icon(Icons.star_rate_rounded, color: Colors.white),
                  label: const Text("Write Review",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              // Secondary Action: Return (Only if within 12h logic holds)
              if (canReturn) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _handleReturnRequest(context),
                    icon:
                        const Icon(Icons.assignment_return_outlined, size: 18),
                    label: const Text("Request Return (Defective Item)",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildBottomContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(child: child),
    );
  }

  Widget _bottomBtn(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed,
      bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
