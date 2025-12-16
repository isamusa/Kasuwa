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

// --- The UI ---
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
    // When the screen is first built, tell the provider to fetch the latest addresses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckoutProvider>(context, listen: false)
          .fetchAddresses(widget.itemsToCheckout);
    });
  }

  void _changeAddress(BuildContext context, CheckoutProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: provider.addresses.length,
          itemBuilder: (ctx, index) {
            final address = provider.addresses[index];
            return ListTile(
              title: Text(address.recipientName),
              subtitle: Text(address.fullAddress),
              onTap: () {
                provider.selectAddress(address, widget.itemsToCheckout);
                Navigator.of(ctx).pop();
              },
            );
          },
        );
      },
    );
  }

  // THE FIX: This method now follows the correct, single-action logic.
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

    // Step 1: Create the order and get the payment URL in a single step.
    final result = await checkoutProvider
        .placeOrderAndInitializePayment(widget.itemsToCheckout);

    if (!mounted) return;

    if (result['success']) {
      // Step 2: Navigate to the payment screen.
      final paymentCompleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OpayPaymentScreen(checkoutUrl: result['url']!),
        ),
      );

      // Step 3: Handle the result from the payment screen.
      if (paymentCompleted == true) {
        // Payment was successful. The backend webhook will handle updating the order.
        // The app's only job is to clear the cart and navigate to the success page.
        Provider.of<CartProvider>(context, listen: false).clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment successful! Your order is being processed.'),
            backgroundColor: Colors.green));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          (route) => route.isFirst,
        );
      } else {
        // User cancelled the payment on the OPay screen.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Payment was cancelled. You can try paying again from the "My Orders" screen.'),
            backgroundColor: Colors.orange));
        // Navigate to the orders screen so they can see the pending order.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          (route) => route.isFirst,
        );
      }
    } else {
      // An error occurred during order creation or payment initialization.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${result['message']}'),
          backgroundColor: Colors.red));
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, child) {
        final currencyFormatter =
            NumberFormat.currency(locale: 'en_NG', symbol: '₦');

        final shippingFee = checkoutProvider.shippingFee;
        final totalAmount = _subtotal + shippingFee;

        return Scaffold(
          appBar: AppBar(
              title: const Text('Checkout'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Shipping Address'),
                _buildAddressSection(context, checkoutProvider),
                const SizedBox(height: 24),
                _buildSectionHeader('Order Summary'),
                _buildOrderSummaryCard(),
                const SizedBox(height: 24),
                _buildPriceDetailsCard(
                    currencyFormatter,
                    _subtotal,
                    shippingFee,
                    totalAmount,
                    checkoutProvider.estimatedDelivery),
              ],
            ),
          ),
          bottomSheet: _buildCheckoutBottomSheet(
              context, currencyFormatter, totalAmount, checkoutProvider),
        );
      },
    );
  }

  Widget _buildAddressSection(BuildContext context, CheckoutProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }
    if (provider.selectedAddress == null) {
      return _buildAddAddressCard(context);
    }
    return _buildAddressCard(context, provider, provider.selectedAddress!);
  }

  Widget _buildAddressCard(BuildContext context, CheckoutProvider provider,
      ShippingAddress address) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppTheme.primaryColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.recipientName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address.fullAddress,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _changeAddress(context, provider),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final addressAdded = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const AddAddressScreen()));
          if (addressAdded == true && mounted) {
            Provider.of<CheckoutProvider>(context, listen: false)
                .fetchAddresses(widget.itemsToCheckout);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt_outlined,
                  color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Add Shipping Address',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemsToCheckout.length,
        itemBuilder: (context, index) {
          final item = widget.itemsToCheckout[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            title:
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('Qty: ${item.quantity}'),
            trailing: Text(NumberFormat.currency(
                    locale: 'en_NG', symbol: '₦', decimalDigits: 0)
                .format(item.price)),
          );
        },
        separatorBuilder: (context, index) =>
            const Divider(indent: 16, endIndent: 16),
      ),
    );
  }

  Widget _buildPriceDetailsCard(NumberFormat currencyFormatter, double subtotal,
      double shippingFee, double totalAmount, String estimatedDelivery) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _priceRow('Subtotal', currencyFormatter.format(subtotal)),
            const SizedBox(height: 8),
            _priceRow('Shipping Fee', currencyFormatter.format(shippingFee)),
            const SizedBox(height: 8),
            _priceRow('Estimated Delivery', estimatedDelivery),
            const Divider(height: 24),
            _priceRow('Total', currencyFormatter.format(totalAmount),
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomSheet(
      BuildContext context,
      NumberFormat currencyFormatter,
      double totalAmount,
      CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount', style: TextStyle(color: Colors.grey[700])),
              Text(currencyFormatter.format(totalAmount),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary)),
            ],
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _proceedToPayment(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade400,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Text('Proceed to Pay',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, String amount, {bool isTotal = false}) {
    final style = TextStyle(
        fontSize: isTotal ? 18 : 16,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        color: isTotal ? AppTheme.textColorPrimary : Colors.grey[800]);
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title, style: style), Text(amount, style: style)]);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary)));
  }
}
