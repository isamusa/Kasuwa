import 'package:flutter/material.dart';
import 'package:kasuwa/screens/order_details_screen.dart';
import 'package:kasuwa/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // --- UPDATED: Fetch latest orders immediately on open ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrders(forceRefresh: true); // Added forceRefresh: true
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Completed"),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return _buildShimmerLoading();
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return _buildErrorState(provider);
          }

          final allOrders = provider.orders;

          final activeOrders = allOrders.where((o) {
            final s = o.status.toLowerCase();
            return [
              'pending',
              'processing',
              'shipped',
              'in transit',
              'payment pending'
            ].contains(s);
          }).toList();

          final completedOrders = allOrders.where((o) {
            final s = o.status.toLowerCase();
            return ['delivered', 'completed'].contains(s);
          }).toList();

          final cancelledOrders = allOrders.where((o) {
            final s = o.status.toLowerCase();
            return ['cancelled', 'failed', 'declined'].contains(s);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(activeOrders, "No active orders",
                  Icons.local_shipping_outlined, provider),
              _buildOrderList(completedOrders, "No completed orders",
                  Icons.check_circle_outline, provider),
              _buildOrderList(cancelledOrders, "No cancelled orders",
                  Icons.cancel_outlined, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderSummary> orders, String emptyMsg,
      IconData emptyIcon, OrderProvider provider) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchOrders(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(emptyMsg,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchOrders(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: orders.length,
        separatorBuilder: (c, i) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCompactOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildCompactOrderCard(OrderSummary order) {
    final statusColor = _getStatusColor(order.status);
    final firstItemImage =
        order.items.isNotEmpty ? order.items.first.imageUrl : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: order.id)));
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 48,
                        width: 48,
                        color: Colors.grey[50],
                        child: firstItemImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: firstItemImage,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => const Icon(
                                    Icons.image_not_supported,
                                    size: 16,
                                    color: Colors.grey),
                              )
                            : const Icon(Icons.shopping_bag,
                                size: 20, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.orderNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(order.totalAmount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.items.map((e) => e.productName).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${order.itemCount} items • ${order.date}",
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCompactStatusChip(order.status, statusColor, true),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey[400])
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusChip(String label, Color color, bool isStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          if (isStatus) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green[600]!;
      case 'shipped':
      case 'in transit':
        return Colors.blue[600]!;
      case 'cancelled':
      case 'failed':
        return Colors.red[600]!;
      case 'processing':
        return Colors.orange[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.white,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(OrderProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text("Couldn't load orders",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.fetchOrders(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Try Again"),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            )
          ],
        ),
      ),
    );
  }
}
