import 'package:flutter/material.dart';
import 'package:kasuwa/providers/seller_order_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/seller_order_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = [
    'all',
    'pending',
    'processing',
    'shipped',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData('all');
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _fetchData(_statuses[_tabController.index]);
    }
  }

  void _fetchData(String status) {
    Provider.of<SellerOrderProvider>(context, listen: false)
        .fetchOrders(status: status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Inject Provider locally if not at root, or assume it's at root.
    // For safety, we can wrap in ChangeNotifierProvider if this is an isolated flow,
    // but usually better to have it in main.dart MultiProvider.
    // Assuming it's in main.dart:

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text("Order Management",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: _statuses.map((s) => Tab(text: s.toUpperCase())).toList(),
        ),
      ),
      body: Consumer<SellerOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No ${_statuses[_tabController.index]} orders",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchData(_statuses[_tabController.index]),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    // Status Color Logic
    Color statusColor = Colors.grey;
    if (order.status == 'pending') statusColor = Colors.orange;
    if (order.status == 'processing') statusColor = Colors.blue;
    if (order.status == 'shipped') statusColor = Colors.purple;
    if (order.status == 'completed') statusColor = Colors.green;
    if (order.status == 'cancelled') statusColor = Colors.red;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SellerOrderDetailsScreen(order: order)));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(order.status.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(order.customerName, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(timeago.format(order.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(currency.format(order.totalAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Text("• ${order.paymentStatus}",
                    style: TextStyle(
                        fontSize: 12,
                        color: order.paymentStatus == 'paid'
                            ? Colors.green
                            : Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
