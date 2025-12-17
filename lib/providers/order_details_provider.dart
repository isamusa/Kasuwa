import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/services/order_details_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/services/checkout_service.dart';

import 'dart:convert';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

// --- Data Models for this Screen ---
class OrderDetailItem {
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final String price;

  OrderDetailItem(
      {required this.productId,
      required this.productName,
      required this.imageUrl,
      required this.quantity,
      required this.price});

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>?;

    return OrderDetailItem(
      productId: product['id'] ?? 0,
      productName: product['name'] ?? 'Product',
      imageUrl: images != null && images.isNotEmpty
          ? storageUrl(images[0]['image_url'])
          : 'https://placehold.co/400/purple/white?text=Kasuwa',
      quantity: json['quantity'] ?? 1,
      price: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(double.tryParse(json['price'].toString()) ?? 0.0),
    );
  }
}

class ShippingAddressDetail {
  final String recipientName;
  final String fullAddress;
  final String phoneNumber;

  ShippingAddressDetail(
      {required this.recipientName,
      required this.fullAddress,
      required this.phoneNumber});

  factory ShippingAddressDetail.fromJson(Map<String, dynamic> json) {
    return ShippingAddressDetail(
      recipientName: json['recipient_name'] ?? json['name'] ?? 'N/A',
      fullAddress:
          '${json['address_line_1'] ?? ''}, ${json['city'] ?? ''}, ${json['state'] ?? ''}',
      phoneNumber: json['recipient_phone'] ?? json['phone_number'] ?? 'N/A',
    );
  }
}

class OrderDetail {
  final int id;
  final String orderNumber;
  String status;
  String paymentStatus;

  final String date;
  final List<OrderDetailItem> items;
  final ShippingAddressDetail shippingAddress;
  final String totalAmount;
  final String shippingFee;
  final double rawShippingFee;
  final double rawTotalAmount;
  final double subtotal;

  OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.date,
    required this.items,
    required this.shippingAddress,
    required this.totalAmount,
    required this.shippingFee,
    required this.rawShippingFee,
    required this.subtotal,
    required this.rawTotalAmount,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // 1. SAFE PARSING: Handle Shipping Address (String, Map, or Null)
    Map<String, dynamic> shippingAddressData = {};
    if (json['shipping_address'] != null) {
      if (json['shipping_address'] is String) {
        try {
          shippingAddressData = jsonDecode(json['shipping_address']);
        } catch (e) {
          print("Error decoding shipping_address: $e");
        }
      } else if (json['shipping_address'] is Map) {
        shippingAddressData =
            Map<String, dynamic>.from(json['shipping_address']);
      }
    }

    // 2. SAFE PARSING: Handle Numbers (String or num)
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final rawShippingFee = parseDouble(json['shipping_fee']);
    final rawTotalAmount = parseDouble(json['total_amount']);
    final subtotal = rawTotalAmount - rawShippingFee;

    return OrderDetail(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? 'N/A',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending_payment',
      date: json['created_at'] != null
          ? DateFormat('d MMMM, yyyy')
              .format(DateTime.parse(json['created_at']))
          : 'Unknown Date',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderDetailItem.fromJson(item))
              .toList() ??
          [],
      shippingAddress: ShippingAddressDetail.fromJson(shippingAddressData),
      totalAmount: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(rawTotalAmount),
      shippingFee: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(rawShippingFee),
      rawTotalAmount: rawTotalAmount,
      rawShippingFee: rawShippingFee,
      subtotal: subtotal,
    );
  }
}

// --- The Provider Class ---
class OrderDetailsProvider with ChangeNotifier {
  final OrderDetailsService _orderService = OrderDetailsService();
  final CheckoutService _checkoutService = CheckoutService();
  final AuthProvider _auth;

  OrderDetail? _order;
  bool _isLoading = false;
  String? _error;
  bool _isRetryingPayment = false;
  bool _isConfirming = false;

  OrderDetail? get order => _order;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRetryingPayment => _isRetryingPayment;
  bool get isConfirming => _isConfirming;

  OrderDetailsProvider(this._auth);

  Future<void> fetchOrderDetails(int orderId) async {
    final token = _auth.token;
    if (token == null) {
      _error = "Not authenticated. Please log in.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _order = await _orderService.getOrderDetails(orderId, token);
    } catch (e) {
      _error = e.toString();
      // Clean up error message for UI
      if (_error!.contains("Exception:")) {
        _error = _error!.replaceAll("Exception:", "").trim();
      }
      print("OrderDetailsProvider Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> retryPayment() async {
    if (_order == null) {
      return {'success': false, 'message': 'Order details not loaded.'};
    }

    _isRetryingPayment = true;
    notifyListeners();

    final token = _auth.token;
    if (token == null) {
      _isRetryingPayment = false;
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      return await _checkoutService.retryOrderPayment(
          orderId: _order!.id, token: _auth.token!);
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred connecting to payment.'
      };
    } finally {
      _isRetryingPayment = false;
      notifyListeners();
    }
  }

  Future<bool> confirmDelivery() async {
    if (_order == null || _isConfirming) return false;

    _isConfirming = true;
    notifyListeners();

    bool success = false;
    try {
      final token = _auth.token;
      if (token == null) throw Exception('Not authenticated');

      success = await _orderService.confirmOrderReceived(_order!.id, token);
      if (success) {
        // Optimistically update status
        _order!.status = 'delivered';
      }
    } catch (e) {
      print('Error confirming delivery: $e');
    }

    _isConfirming = false;
    notifyListeners();
    return success;
  }
}
