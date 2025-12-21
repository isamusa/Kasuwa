import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/add_product_screen.dart';
import 'package:kasuwa/services/product_service.dart';
import 'package:kasuwa/providers/dashboard_provider.dart';
import 'package:kasuwa/screens/edit_shop.dart';
import 'package:kasuwa/screens/edit_product_screen.dart';
import 'package:kasuwa/screens/contact_admin_screen.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/models/notification_model.dart';
import 'package:kasuwa/screens/seller_orders_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});
  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with WidgetsBindingObserver {
  final ProductService _productService = ProductService();

  // Navigation State
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Data State
  String _selectedDateRange = 'Last 7 Days';
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inventorySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData();
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  // --- CHANGED: Returns Future<void> for RefreshIndicator ---
  Future<void> _fetchData() async {
    if (mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        await Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboardData();
      }
    }
  }

  void _startTimer() {
    _stopTimer();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _fetchData());
  }

  void _stopTimer() => _refreshTimer?.cancel();

  @override
  void dispose() {
    _inventorySearchController.dispose();
    _scrollController.dispose();
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleProductStatusToggle(int productId, bool currentStatus) async {
    final success = await _productService.toggleProductStatus(productId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Status updated"), backgroundColor: Colors.green));
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Update failed"), backgroundColor: Colors.red));
      }
    }
  }

  void _handleProductDelete(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
            "Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await _productService.deleteProduct(productId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Product deleted successfully"),
              backgroundColor: Colors.green));
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to delete product"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F7FE),
          drawer: _buildSidebar(context),
          body: _buildMainContent(provider),
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddProductScreen()))
                      .then((_) => provider.fetchDashboardData()),
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 4,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Product",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                )
              : null,
        );
      },
    );
  }

  // --- Sidebar Navigation ---
  Widget _buildSidebar(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final name = user?['name'] ?? 'Seller';
    final email = user?['email'] ?? '';
    final avatar = user?['profile_picture_url'];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
            accountName: Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail:
                Text(email, style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  (avatar != null) ? CachedNetworkImageProvider(avatar) : null,
              child: (avatar == null)
                  ? const Icon(Icons.person,
                      size: 40, color: AppTheme.primaryColor)
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, "Dashboard", Icons.dashboard_outlined),
                _buildDrawerItem(1, "Inventory", Icons.inventory_2_outlined),
                _buildDrawerItem(2, "Orders", Icons.shopping_bag_outlined),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text("SHOP MANAGEMENT",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                _buildDrawerItem(3, "Shop Profile", Icons.storefront_outlined),
                _buildDrawerItem(4, "Support", Icons.support_agent_outlined),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false);
            },
          ),
          SizedBox(height: 20 + bottomPadding),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey[600]),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // --- Main Content Switcher ---
  Widget _buildMainContent(DashboardProvider provider) {
    if (provider.isLoading && provider.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.summary == null) {
      return Center(child: Text("Error: ${provider.error}"));
    }

    final summary = provider.summary!;
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView(provider, summary, currency);
      case 1:
        return _buildInventoryView(provider, currency);
      case 2:
        return _buildOrdersView(provider);
      case 3:
        return const EditShopProfileScreen();
      case 4:
        return const ContactAdminScreen();
      default:
        return _buildDashboardView(provider, summary, currency);
    }
  }

  // --- VIEW 1: Dashboard Overview ---
  Widget _buildDashboardView(DashboardProvider provider,
      DashboardSummary summary, NumberFormat currency) {
    final double bottomPadding = 80 + MediaQuery.of(context).padding.bottom;

    // --- CHANGED: Added RefreshIndicator ---
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        // Important: Allows pull-to-refresh even if content is short
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF311B92)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(_selectedDateRange,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.trending_up,
                                color: Colors.greenAccent),
                          ],
                        ),
                        const Spacer(),
                        const Text("Total Revenue",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(currency.format(summary.totalRevenue),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0)),
                        const SizedBox(height: 8),
                        Text("${summary.totalOrders} total orders processed",
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text("Overview"),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStatsGrid(summary),
                  const SizedBox(height: 24),
                  _buildChartSection(provider.salesData),
                  const SizedBox(height: 24),
                  _buildRecentActivity(provider.notifications),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Products",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => setState(() => _selectedIndex = 1),
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildProductListSliver(
              provider.filteredProducts.take(5).toList(), currency,
              isPreview: true),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
    );
  }

  // --- VIEW 2: Inventory ---
  Widget _buildInventoryView(
      DashboardProvider provider, NumberFormat currency) {
    final double bottomPadding = 100 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _inventorySearchController,
              onChanged: (val) => provider.filterProducts(val),
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      // --- CHANGED: Added RefreshIndicator ---
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver:
                  _buildProductListSliver(provider.filteredProducts, currency),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
          ],
        ),
      ),
    );
  }

  // --- VIEW 3: Orders ---
  Widget _buildOrdersView(DashboardProvider provider) {
    return const SellerOrdersScreen();
  }

  // --- Components ---

  Widget _buildProductListSliver(
      List<SellerProduct> products, NumberFormat currency,
      {bool isPreview = false}) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text("No products found",
                style: TextStyle(color: Colors.grey[500])),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[100], child: const Icon(Icons.image)),
                ),
              ),
              title: Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(product.price,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(
                          label: "Stock: ${product.stockQuantity}",
                          color: product.stockQuantity > 0
                              ? Colors.green
                              : Colors.red),
                      const SizedBox(width: 8),
                      _buildTag(
                          label: product.isActive ? "Active" : "Hidden",
                          color: product.isActive ? Colors.blue : Colors.grey),
                    ],
                  )
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProductScreen(
                                productId: product.id))).then((_) =>
                        context.read<DashboardProvider>().fetchDashboardData());
                  } else if (v == 'toggle') {
                    _handleProductStatusToggle(product.id, product.isActive);
                  } else if (v == 'delete') {
                    _handleProductDelete(product.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text("Edit")
                      ])),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                            product.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(product.isActive ? "Deactivate" : "Activate")
                      ])),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red))
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: products.length,
      ),
    );
  }

  // ... (Rest of your existing helper widgets like _buildTag, _buildQuickStatsGrid, etc. remain unchanged) ...
  Widget _buildTag({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickStatsGrid(DashboardSummary summary) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard("Total Orders", "${summary.totalOrders}",
                Icons.shopping_bag_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard("Pending", "${summary.pendingOrders}",
                Icons.access_time, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard("Products", "${summary.totalProducts}",
                Icons.inventory_2_outlined, Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<FlSpot> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sales Analytics",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: data.isEmpty
                ? Center(
                    child: Text("No sales data yet",
                        style: TextStyle(color: Colors.grey[400])))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              if (val.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(days[val.toInt()],
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: data.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.y,
                              color: AppTheme.primaryColor,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: (data
                                        .map((p) => p.y)
                                        .reduce((a, b) => a > b ? a : b)) *
                                    1.2,
                                color: const Color(0xFFF0F0F0),
                              ),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<AppNotification> notifications) {
    if (notifications.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent Activity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.take(3).length,
            separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1)),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue[50], shape: BoxShape.circle),
                    child: Icon(Icons.notifications_active_outlined,
                        size: 16, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(timeago.format(notif.createdAt),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
