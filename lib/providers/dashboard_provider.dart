import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/services/dashboard_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/notification_provider.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

class DashboardSummary {
  final double totalRevenue;
  final int pendingOrders;
  final int processingOrders;
  final int completedOrders;
  final int totalShops;
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;

  DashboardSummary({
    required this.totalRevenue,
    required this.pendingOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.totalShops,
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalRevenue:
            double.tryParse(json['total_revenue']?.toString() ?? '0.0') ?? 0.0,
        pendingOrders: json['pending_orders'] ?? 0,
        processingOrders: json['processing_orders'] ?? 0,
        completedOrders: json['completed_orders'] ?? 0,
        totalShops: json['total_shops'] ?? 0,
        totalProducts: json['total_products'] ?? 0,
        activeProducts: json['active_products'] ?? 0,
        inactiveProducts: json['inactive_products'] ?? 0,
      );
}

class SellerProduct {
  final int id;
  final String name;
  final String price;
  final int stockQuantity;
  final String imageUrl;
  final bool isActive;

  SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.isActive,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    final price = (double.tryParse(json['price'].toString()) ?? 0.0);
    final formattedPrice =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦').format(price);
    final images = json['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty
        ? storageUrl(images[0]['image_url'])
        : 'https://placehold.co/400/purple/white?text=Kasuwa';

    return SellerProduct(
      id: json['id'],
      name: json['name'],
      price: formattedPrice,
      stockQuantity: json['stock_quantity'],
      imageUrl: imageUrl,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final AuthProvider _auth;
  final NotificationProvider _notificationProvider;

  DashboardSummary? _summary;
  List<SellerProduct> _allProducts = [];
  List<SellerProduct> _filteredProducts = [];
  List<FlSpot> _salesData = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedData = false;

  // Public getters
  DashboardSummary? get summary => _summary;
  List<SellerProduct> get filteredProducts => _filteredProducts;
  List<AppNotification> get notifications => _notificationProvider.notifications
      .where((n) => n.notifiableType.contains('Shop'))
      .toList();
  List<FlSpot> get salesData => _salesData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DashboardProvider(this._auth, this._notificationProvider);

  void update(AuthProvider auth, NotificationProvider notificationProvider) {
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchDashboardData();
    }
    if (!auth.isAuthenticated && _hasFetchedData) {
      _clearData();
    }
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    _hasFetchedData = true;
    notifyListeners();

    try {
      final data = await _dashboardService.fetchDashboardData();
      _summary = data['summary'];
      _allProducts = data['products'];
      _filteredProducts = _allProducts;
      _salesData = data['salesData'];
    } catch (e) {
      _error = e.toString();
      log("Dashboard Provider Error: $_error");
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void _clearData() {
    _summary = null;
    _allProducts = [];
    _filteredProducts = [];
    _salesData = [];
    _hasFetchedData = false;
    _error = null;
    notifyListeners();
    log("Dashboard data cleared due to logout.");
  }
}
