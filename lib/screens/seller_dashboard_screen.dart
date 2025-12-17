import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/add_product_screen.dart';
import 'package:kasuwa/services/product_service.dart';
import 'package:kasuwa/providers/dashboard_provider.dart';
import 'package:kasuwa/screens/edit_shop.dart';
import 'package:kasuwa/providers/notification_provider.dart';
import 'package:kasuwa/screens/edit_product_screen.dart';
import 'package:kasuwa/screens/contact_admin_screen.dart';
import 'package:provider/provider.dart';
//import 'package:kasuwa/screens/shop_notifications_screen.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});
  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with WidgetsBindingObserver {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateRange = 'Last 7 Days';

  // Timer for live data refreshing
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboardData();
    });
    _fetchData();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App has returned to the foreground, refresh data and restart the timer
      _fetchData();
      _startTimer();
    } else {
      // App is in the background or paused, stop the timer to save resources
      _stopTimer();
    }
  }

  void _fetchData() {
    // Ensure the provider is available before fetching
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboardData();
      }
    }
  }

  void _startTimer() {
    // Ensure any existing timer is stopped before starting a new one
    _stopTimer();
    // Create a new timer that fetches data every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print("Dashboard auto-refreshing...");
      _fetchData();
    });
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stopTimer(); // Always cancel the timer when the screen is disposed
    WidgetsBinding.instance.removeObserver(this); // Clean up the observer
    super.dispose();
  }

  void _handleProductAction(Future<bool> Function() action,
      String successMessage, String errorMessage) async {
    final success = await action();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? successMessage : errorMessage),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) {
        Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: _buildAppBar(),
          body: _buildBody(dashboardProvider),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddProductScreen()))
                .then((_) => dashboardProvider.fetchDashboardData()),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add New Product',
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Text('My Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Navigator.push(
            //  context,
            //    MaterialPageRoute(builder: (_) => const ShopNotificationScreen()),
            //    );
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _selectedDateRange = value),
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => ['Last 7 Days', 'This Month', 'This Year']
              .map((range) => PopupMenuItem(value: range, child: Text(range)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBody(DashboardProvider provider) {
    if (provider.isLoading && provider.summary == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (provider.error != null) {
      final errorMessage = provider.error!.toLowerCase();
      final isOffline = errorMessage.contains('offline') ||
          errorMessage.contains('socketexception') ||
          errorMessage.contains('network is unreachable');

      return _buildErrorWidget(
        title: isOffline ? "You're Offline" : "An Error Occurred",
        message: isOffline
            ? "Please check your internet connection and try again."
            : "We couldn't load your dashboard. Please try again later.",
        icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        onRetry: () => provider.fetchDashboardData(),
      );
    }

    if (provider.summary == null) {
      return _buildErrorWidget(
        title: "Authentication Required",
        message: "Please log in to view your seller dashboard.",
        icon: Icons.lock_outline_rounded,
        onRetry: () =>
            Provider.of<AuthProvider>(context, listen: false).refreshUser(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardData(),
      color: AppTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummarySection(provider.summary!),
          const SizedBox(height: 24),
          _buildSalesChartSection(provider.salesData),
          const SizedBox(height: 24),
          _buildActivitySection(provider.notifications),
          const SizedBox(height: 24),
          _buildShopManagementSection(),
          const SizedBox(height: 24),
          _buildProductsSection(provider),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
      {required String title,
      required String message,
      required IconData icon,
      required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_selectedDateRange,
            style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 12),
        // Use Wrap for a responsive layout
        Wrap(
          spacing: 16, // Horizontal space
          runSpacing: 16, // Vertical space
          children: [
            _buildStatCard(
                'Total Revenue',
                NumberFormat.currency(locale: 'en_NG', symbol: '₦')
                    .format(summary.totalRevenue),
                Icons.monetization_on_outlined,
                Colors.green.shade600),
            _buildStatCard('Pending Orders', summary.pendingOrders.toString(),
                Icons.pending_actions_outlined, Colors.orange.shade700),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Ensure card takes minimum space
          children: [
            Icon(icon, size: 25, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(title,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChartSection(List<FlSpot> salesData) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Chart',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: salesData.isEmpty
                  ? Center(child: Text("No sales data available."))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: salesData
                                .map((e) => e.y)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: const FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        gridData: const FlGridData(show: true),
                        barGroups: salesData.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                  toY: e.value.y,
                                  color: AppTheme.primaryColor,
                                  width: 15,
                                  borderRadius: BorderRadius.circular(4))
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(List<AppNotification> notifications) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Activity',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              TextButton(
                  onPressed: () {
                    //  Navigator.push(
                    //  context,
                    //MaterialPageRoute(
                    //  builder: (_) => const ShopNotificationScreen()),
                    // );
                  },
                  child: const Text('View All'))
            ]),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                    child: Text("No recent activity.",
                        style: TextStyle(color: Colors.grey[600]))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.take(3).length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notification.message),
                    trailing: Text(timeago.format(notification.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  );
                },
                separatorBuilder: (ctx, i) => const Divider(height: 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopManagementSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Shop Management',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined,
                color: AppTheme.primaryColor),
            title: const Text('Edit Shop Profile'),
            subtitle:
                const Text('Update your shop name, description, and logo.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditShopProfileScreen()));
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined,
                color: AppTheme.primaryColor),
            title: const Text('Contact Admin'),
            subtitle:
                const Text('Get help with orders, payments, or your account.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContactAdminScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Products (${provider.filteredProducts.length})',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            TextButton(onPressed: () {}, child: const Text('See All'))
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: provider.filterProducts,
          decoration: InputDecoration(
            hintText: 'Search my products...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        if (provider.filteredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(_searchController.text.isEmpty
                  ? 'You have not added any products yet.'
                  : 'No products found for "${_searchController.text}".'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = provider.filteredProducts[index];
              return _buildProductListItem(product);
            },
          ),
      ],
    );
  }

  Widget _buildProductListItem(SellerProduct product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (c, o, s) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(product.price,
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EditProductScreen(productId: product.id)))
                          .then((_) {
                        Provider.of<DashboardProvider>(context, listen: false)
                            .fetchDashboardData();
                      });
                    } else if (value == 'delete') {
                      _handleProductAction(
                          () => _productService.deleteProduct(product.id),
                          'Product deleted.',
                          'Failed to delete.');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stock: ${product.stockQuantity}',
                    style: TextStyle(color: Colors.grey[700])),
                Row(
                  children: [
                    Text(product.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            color:
                                product.isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Switch(
                      value: product.isActive,
                      onChanged: (value) => _handleProductAction(
                          () => _productService.toggleProductStatus(product.id),
                          'Status updated.',
                          'Failed to update.'),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
