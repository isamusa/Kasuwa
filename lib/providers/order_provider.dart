import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/services/order_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  // 1. If it's already a full URL (Cloudinary), return it as is.
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }

  // 2. If it's a legacy relative path, prepend the Render base URL.
  return '${AppConfig.baseUrl}/storage/$path';
}

class OrderSummary {
  final int id;
  final String orderNumber;
  final String status;
  final String payment;

  final String totalAmount;
  final String date;
  final int itemCount;
  final List<OrderItemSnippet> items;

  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.payment,
    required this.totalAmount,
    required this.date,
    required this.itemCount,
    required this.items,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map((item) => OrderItemSnippet.fromJson(item))
        .toList();
    return OrderSummary(
      id: json['id'],
      orderNumber: json['order_number'] ?? '#${json['id']}',
      status: toTitleCase(json['status'] ?? 'pending'),
      payment: toTitleCase(json['payment_status'] ?? 'pending payment'),
      totalAmount: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(double.tryParse(json['total_amount'].toString()) ?? 0.0),
      date:
          DateFormat('d MMMM, yyyy').format(DateTime.parse(json['created_at'])),
      itemCount: items.length,
      items: items,
    );
  }

  static String toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

class OrderItemSnippet {
  final String productName;
  final String imageUrl;
  OrderItemSnippet({required this.productName, required this.imageUrl});

  factory OrderItemSnippet.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>?;
    return OrderItemSnippet(
      productName: product['name'] ?? 'Product',
      imageUrl: images != null && images.isNotEmpty
          ? storageUrl(images[0]['image_url'])
          : 'https://placehold.co/400/purple/white?text=Kasuwa',
    );
  }
}

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final AuthProvider _auth;

  List<OrderSummary> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedData = false;

  List<OrderSummary> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider(this._auth);

  void update(AuthProvider auth) {
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchOrders();
    }
    if (!auth.isAuthenticated && _hasFetchedData) {
      _clearOrders();
    }
  }

  Future<void> fetchOrders({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    if (forceRefresh) notifyListeners();

    try {
      final token = _auth.token;
      final ordersData = await _orderService.getOrders(
          token: token, forceRefresh: forceRefresh);
      _orders = ordersData
          .map((itemData) => OrderSummary.fromJson(itemData))
          .toList();
      _hasFetchedData = true;
    } catch (e) {
      _error = e.toString();
      print("OrderProvider Error: $_error");
    }

    _isLoading = false;
    notifyListeners();
  }

  void _clearOrders() {
    _orders = [];
    _hasFetchedData = false;
    _error = null;
    notifyListeners();
  }
}
