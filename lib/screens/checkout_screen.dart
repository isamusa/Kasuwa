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
      Provider.of<CheckoutProvider>(context, listen: false).fetchAddresses();
    });
  }

  void _changeAddress(BuildContext context, CheckoutProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Shipping Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[200]),
              Expanded(
                child: ListView.separated(
                  itemCount: provider.addresses.length,
                  separatorBuilder: (c, i) => Divider(color: Colors.grey[100]),
                  itemBuilder: (ctx, index) {
                    final address = provider.addresses[index];
                    return ListTile(
                      leading: Icon(
                          address.isDefault
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: AppTheme.primaryColor),
                      title: Text(address.recipientName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(address.fullAddress),
                      onTap: () {
                        provider.selectAddress(address, widget.itemsToCheckout);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddAddressScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add New Address"),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primaryColor)),
                  ),
                ),
              )
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isProcessing = true);

    final result = await checkoutProvider
        .placeOrderAndInitializePayment(widget.itemsToCheckout);

    if (!mounted) return;

    if (result['success']) {
      final paymentCompleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OpayPaymentScreen(checkoutUrl: result['url']!),
        ),
      );

      if (!mounted) return;

      if (paymentCompleted == true) {
        Provider.of<CartProvider>(context, listen: false).clear();

        // --- CHANGED THIS SECTION ---
        // Old: Navigate directly to MyOrdersScreen
        // New: Navigate to PaymentSuccessScreen
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Order placed successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment cancelled. You can retry from Orders.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          (route) => route.isFirst,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${result['message']}'),
          behavior: SnackBarBehavior.floating,
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
        final currencyFormatter = NumberFormat.currency(
            locale: 'en_NG', symbol: '₦', decimalDigits: 0);

        final shippingFee = checkoutProvider.shippingFee;
        final totalAmount = _subtotal + shippingFee;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: const Text('Checkout',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('SHIPPING'),
                _buildAddressSection(context, checkoutProvider),
                const SizedBox(height: 24),
                _buildSectionLabel('PAYMENT METHOD'),
                _buildPaymentMethodCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('ORDER ITEMS'),
                _buildOrderItemsList(),
                const SizedBox(height: 24),
                _buildSectionLabel('ORDER SUMMARY'),
                _buildPriceDetailsCard(
                    currencyFormatter,
                    _subtotal,
                    shippingFee,
                    totalAmount,
                    checkoutProvider.estimatedDelivery),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gpp_good, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Text("SSL Secure Checkout",
                          style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12))
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(
              context, currencyFormatter, totalAmount, checkoutProvider),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0)),
    );
  }

  Widget _buildAddressSection(BuildContext context, CheckoutProvider provider) {
    if (provider.isLoading) {
      return Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: CircularProgressIndicator()));
    }
    if (provider.selectedAddress == null) {
      return _buildAddAddressCard(context);
    }
    return _buildAddressCard(context, provider, provider.selectedAddress!);
  }

  Widget _buildAddressCard(BuildContext context, CheckoutProvider provider,
      ShippingAddress address) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(address.recipientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                TextButton(
                  onPressed: () => _changeAddress(context, provider),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('CHANGE',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28.0),
              child: Text(address.fullAddress,
                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 4),
              child: Text(address.phone,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressCard(BuildContext context) {
    return InkWell(
      onTap: () async {
        final addressAdded = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => const AddAddressScreen()));
        if (addressAdded == true && mounted) {
          Provider.of<CheckoutProvider>(context, listen: false)
              .fetchAddresses();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primaryColor, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_location_alt_outlined,
                color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            const Text('Add Shipping Address',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.account_balance_wallet, color: Colors.green[700]),
        ),
        title: const Text("Pay via OPay",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Cards, Bank Transfer, USSD"),
        trailing: Icon(Icons.check_circle, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildOrderItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemsToCheckout.length,
        itemBuilder: (context, index) {
          final item = widget.itemsToCheckout[index];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
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
                Text(
                    NumberFormat.currency(
                            locale: 'en_NG', symbol: '₦', decimalDigits: 0)
                        .format(item.price * item.quantity),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  Widget _buildPriceDetailsCard(NumberFormat currencyFormatter, double subtotal,
      double shippingFee, double totalAmount, String estimatedDelivery) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _priceRow('Subtotal', currencyFormatter.format(subtotal)),
          const SizedBox(height: 12),
          _priceRow('Shipping Fee', currencyFormatter.format(shippingFee)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Delivery',
                  style: TextStyle(color: Colors.grey[600])),
              Text(estimatedDelivery,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          // Dotted or Dashed line could go here
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(currencyFormatter.format(totalAmount),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, NumberFormat currencyFormatter,
      double totalAmount, CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total to Pay',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(currencyFormatter.format(totalAmount),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed:
                    _isProcessing ? null : () => _proceedToPayment(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Order',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String title, String amount) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
      Text(amount,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))
    ]);
  }
}
