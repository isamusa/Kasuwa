import 'package:flutter/material.dart';
import 'package:kasuwa/models/seller_order_model.dart';
import 'package:kasuwa/providers/seller_order_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/theme/app_theme.dart';
// import 'package:kasuwa/config/app_config.dart'; // unused in this screen
import 'package:cached_network_image/cached_network_image.dart';

class SellerOrderDetailsScreen extends StatefulWidget {
  final SellerOrder order;
  const SellerOrderDetailsScreen({super.key, required this.order});

  @override
  State<SellerOrderDetailsScreen> createState() =>
      _SellerOrderDetailsScreenState();
}

class _SellerOrderDetailsScreenState extends State<SellerOrderDetailsScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  void _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final success =
        await Provider.of<SellerOrderProvider>(context, listen: false)
            .updateStatus(widget.order.id, newStatus);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Order Status Updated"),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to update"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text("Order #${widget.order.orderNumber}",
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Update Status",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Info
            _buildSection(title: "Customer Details", children: [
              _buildInfoRow(Icons.person, widget.order.customerName),
              _buildInfoRow(Icons.phone, widget.order.customerPhone),
              _buildInfoRow(Icons.location_on, widget.order.shippingAddress),
            ]),
            const SizedBox(height: 16),

            // Items
            _buildSection(
                title: "Items (${widget.order.items.length})",
                children: widget.order.items
                    .map((item) => _buildItemRow(item, currency))
                    .toList()),

            const SizedBox(height: 16),

            // Payment
            _buildSection(title: "Payment Summary", children: [
              _buildSummaryRow(
                  "Status", widget.order.paymentStatus.toUpperCase(),
                  isBold: true),
              const Divider(),
              _buildSummaryRow(
                  "Total Amount", currency.format(widget.order.totalAmount),
                  isTotal: true),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    const statuses = [
      'processing',
      'shipped',
    ];
    const terminalStatuses = {'completed', 'delivered'};
    final isTerminal = terminalStatuses.contains(_currentStatus.toLowerCase());
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // Use `value` when current status is one of the available options,
                // otherwise show it as a hint so the dropdown can display safely.
                value:
                    statuses.contains(_currentStatus) ? _currentStatus : null,
                hint: Text(_currentStatus.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                // When the order is in a terminal state we disable the control
                // and show the current status as the disabled hint.
                disabledHint: Text(_currentStatus.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                isExpanded: true,
                items: statuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
                onChanged: (_isUpdating || isTerminal)
                    ? null
                    : (v) {
                        if (v != null) _updateStatus(v);
                      },
              ),
            ),
          ),
        ),
        if (_isUpdating)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildItemRow(SellerOrderItem item, NumberFormat currency) {
    // The Model now handles the URL logic, so we use item.imageUrl directly.
    print(item.imageUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl, // No need for manual concatenation
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorWidget: (c, e, s) => Container(color: Colors.grey[200]),
              placeholder: (c, url) => Container(color: Colors.grey[100]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (item.variant != null)
                  Text(item.variant!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("x${item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(currency.format(item.price * item.quantity),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isBold || isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? AppTheme.primaryColor : Colors.black)),
        ],
      ),
    );
  }
}
