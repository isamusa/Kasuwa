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
      quantity: json['quantity'],
      price: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(double.parse(json['price'].toString())),
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
          '${json['address_line_1']}, ${json['city']}, ${json['state']}',
      phoneNumber: json['recipient_phone'] ?? 'N/A', // Corrected key
    );
  }
}

class OrderDetail {
  final int id; // Added ID for API calls
  final String orderNumber;
  String status; // Made non-final to allow local updates
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
    final shippingAddressData = jsonDecode(json['shipping_address']);
    final rawShippingFee = jsonDecode(json['shipping_fee']);

    final rawTotalAmount = jsonDecode(json['total_amount']);

    final subtotal = rawTotalAmount - rawShippingFee;

    return OrderDetail(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      paymentStatus: json['payment_status'] ?? 'pending_payment',
      date:
          DateFormat('d MMMM, yyyy').format(DateTime.parse(json['created_at'])),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderDetailItem.fromJson(item))
          .toList(),
      shippingAddress: ShippingAddressDetail.fromJson(shippingAddressData),
      totalAmount: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(double.parse(json['total_amount'])),
      shippingFee: NumberFormat.currency(locale: 'en_NG', symbol: '₦')
          .format(double.parse(json['shipping_fee'])),
      rawTotalAmount: double.parse(json['total_amount'].toString()),
      rawShippingFee: double.parse(json['shipping_fee'].toString()),
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
  // Add a state variable to track the confirmation process
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
      print("OrderDetailsProvider Error: $_error");
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
      return {'success': false, 'message': 'An error occurred.'};
    } finally {
      _isRetryingPayment = false;
      notifyListeners();
    }
  }

  // THE FIX: Add the method to handle confirming the delivery.
  Future<bool> confirmDelivery() async {
    if (_order == null || _isConfirming) return false;

    _isConfirming = true;
    notifyListeners();

    bool success = false;
    try {
      final token = _auth.token;
      if (token == null) throw Exception('Not authenticated');
      // Assuming OrderDetailsService has this method from our previous implementation
      success = await _orderService.confirmOrderReceived(_order!.id, token);
      if (success) {
        // Optimistically update the local state to reflect the change immediately
        _order!.status = 'delivered';
      }
    } catch (e) {
      print('Error confirming delivery: $e');
      // You could set an error message here if you want to display it in the UI
    }

    _isConfirming = false;
    notifyListeners();
    return success;
  }
}
