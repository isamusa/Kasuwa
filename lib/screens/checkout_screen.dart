import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/opay_payment_screen.dart';
import 'package:kasuwa/screens/add_address_screen.dart';
import 'package:kasuwa/screens/my_orders_screen.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/payment_success_screen.dart';
import 'package:kasuwa/screens/payment_failed_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutCartItem> itemsToCheckout;
  const CheckoutScreen({super.key, required this.itemsToCheckout});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  double get _subtotal => widget.itemsToCheckout
      .fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckoutProvider>(context, listen: false)
          .fetchAddresses(items: widget.itemsToCheckout);
    });
  }

  void _changeAddress(BuildContext context, CheckoutProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Address",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddAddressScreen()));
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add New"),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.addresses.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (ctx, index) {
                    final address = provider.addresses[index];
                    final isSelected =
                        provider.selectedAddress?.id == address.id;
                    return InkWell(
                      onTap: () {
                        provider.selectAddress(address, widget.itemsToCheckout);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.05)
                              : Colors.white,
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade200,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: address.id,
                              groupValue: provider.selectedAddress?.id,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (_) {
                                provider.selectAddress(
                                    address, widget.itemsToCheckout);
                                Navigator.of(ctx).pop();
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(address.recipientName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(address.fullAddress,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(address.phone,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _proceedToPayment(BuildContext context) async {
    final checkoutProvider =
        Provider.of<CheckoutProvider>(context, listen: false);

    if (checkoutProvider.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add or select a shipping address.'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isProcessing = true);

    // 1. Create the order on the backend
    final result = await checkoutProvider
        .placeOrderAndInitializePayment(widget.itemsToCheckout);

    if (!mounted) return;

    if (result['success']) {
      // 2. CRITICAL FIX: Clear the local cart immediately.
      // The backend has already converted these items into an Order.
      // Clearing this prevents "Ghost Orders" if the user navigates back.
      Provider.of<CartProvider>(context, listen: false).clearCart();

      // 3. Navigate to Payment Gateway
      final paymentCompleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OpayPaymentScreen(checkoutUrl: result['url']!),
        ),
      );

      if (!mounted) return;

      if (paymentCompleted == true) {
        // 4a. Success Case
        Provider.of<CheckoutProvider>(context, listen: false)
            .resetOrderTracking();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()));
      } else {
        // 4b. Failure/Cancel Case
        // Navigate to the Failed screen instead of staying on Checkout
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
      }
    } else {
      // API Error (Order creation failed)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${result['message']}'),
          backgroundColor: Colors.red));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, child) {
        final currencyFormatter = NumberFormat.currency(
            locale: 'en_NG', symbol: '₦', decimalDigits: 0);

        final shippingFee = checkoutProvider.shippingFee;
        final totalAmount = _subtotal + shippingFee;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text("Checkout"),
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader("DELIVERY"),
                    _buildAddressCard(context, checkoutProvider),
                    const SizedBox(height: 24),
                    _buildSectionHeader("PAYMENT"),
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("ITEMS"),
                    _buildOrderItemsList(currencyFormatter),
                    const SizedBox(height: 24),
                    _buildSummaryCard(currencyFormatter, _subtotal, shippingFee,
                        totalAmount, checkoutProvider),
                    const SizedBox(height: 100), // Space for bottom bar
                  ]),
                ),
              ),
            ],
          ),
          bottomSheet: _buildBottomBar(
              context, currencyFormatter, totalAmount, checkoutProvider),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 1.2)),
    );
  }

  Widget _buildAddressCard(BuildContext context, CheckoutProvider provider) {
    if (provider.isLoading) {
      return ShimmerPlaceholder(height: 100);
    }

    if (provider.selectedAddress == null) {
      return GestureDetector(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddAddressScreen()));
          provider.fetchAddresses(items: widget.itemsToCheckout);
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor, width: 1),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.add_location_alt_outlined,
                  size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text("Add Shipping Address",
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final address = provider.selectedAddress!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.location_on,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(address.recipientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () => _changeAddress(context, provider),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: const Text("CHANGE",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address.fullAddress,
                          style:
                              TextStyle(color: Colors.grey[600], height: 1.4)),
                      const SizedBox(height: 4),
                      Text(address.phone,
                          style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Image.asset('assets/images/opay_logo.png',
            width: 40, height: 40), // Ensure asset exists
        title: const Text("OPay Payment",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Secure checkout via OPay gateway"),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildOrderItemsList(NumberFormat formatter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemsToCheckout.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = widget.itemsToCheckout[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey[100]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.variantDescription != null)
                        Text(item.variantDescription!,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("Qty: ${item.quantity}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Text(formatter.format(item.price * item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat formatter, double subtotal,
      double shipping, double total, CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", formatter.format(subtotal)),
          const SizedBox(height: 12),
          _summaryRow("Shipping", formatter.format(shipping)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _summaryRow("Total", formatter.format(total), isTotal: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 16, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text("Est. Delivery: ${provider.estimatedDelivery}",
                  style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                color: isTotal ? AppTheme.primaryColor : Colors.black)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, NumberFormat formatter,
      double total, CheckoutProvider provider) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _proceedToPayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pay ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(formatter.format(total),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
        ),
      ),
    );
  }
}

// Simple Placeholder for Loading
class ShimmerPlaceholder extends StatelessWidget {
  final double height;
  const ShimmerPlaceholder({super.key, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
    );
  }
}
