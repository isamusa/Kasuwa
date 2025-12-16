import 'package:flutter/material.dart';
import 'package:kasuwa/services/checkout_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';

// --- Data Models (unchanged) ---
class CheckoutCartItem {
  final int productId;
  final String imageUrl;
  final String name;
  final double price;
  final int quantity;
  final String? variantDescription;

  CheckoutCartItem({
    required this.productId,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.quantity,
    this.variantDescription,
  });
}

class ShippingAddress {
  final int id;
  final String recipientName;
  final String fullAddress;
  final String phone;
  final bool isDefault;

  ShippingAddress(
      {required this.id,
      required this.recipientName,
      required this.fullAddress,
      required this.phone,
      required this.isDefault});

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      recipientName: json['recipient_name'] ?? 'N/A',
      fullAddress:
          '${json['address_line_1']}, ${json['city']}, ${json['state']}',
      phone: json['recipient_phone'] ?? 'N/A',
      isDefault: json['is_default'] == 1,
    );
  }
}

// --- The Provider ---
class CheckoutProvider with ChangeNotifier {
  final CheckoutService _checkoutService = CheckoutService();
  final OrderService _orderService = OrderService();
  final AuthProvider _auth;

  List<ShippingAddress> _addresses = [];
  ShippingAddress? _selectedAddress;
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedData = false;
  double _shippingFee = 1500.00; // Start with a default
  String _estimatedDelivery = "1-2 business days";

  List<ShippingAddress> get addresses => _addresses;
  ShippingAddress? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public Getters for new state
  double get shippingFee => _shippingFee;
  String get estimatedDelivery => _estimatedDelivery;

  CheckoutProvider(this._auth);

  void update(AuthProvider auth) {
    if (auth.isAuthenticated && !_hasFetchedData) {}
  }

  Future<void> fetchAddresses(List<CheckoutCartItem> items) async {
    _isLoading = true;
    _hasFetchedData = true;
    notifyListeners();
    try {
      final token = _auth.token;
      if (token == null) throw Exception('Not authenticated');
      _addresses = await _checkoutService.getShippingAddresses(token);
      if (_addresses.isNotEmpty) {
        _selectedAddress = _addresses.firstWhere((a) => a.isDefault,
            orElse: () => _addresses.first);
        // After fetching addresses, immediately calculate the fee for the default address.
        await calculateShippingFee(items);
      }
      _error = null;
    } catch (e) {
      _error = "Could not load shipping addresses.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Method to calculate the shipping fee.
  Future<void> calculateShippingFee(List<CheckoutCartItem> items) async {
    final token = _auth.token;
    if (token == null || _selectedAddress == null || items.isEmpty) return;

    try {
      final productIds = items.map((item) => item.productId).toList();
      final result = await _checkoutService.getShippingFee(
          token, _selectedAddress!.id, productIds);

      _shippingFee =
          double.tryParse(result['shipping_fee']?.toString() ?? '1500.0') ??
              1500.0;
      _estimatedDelivery = result['estimated_delivery'] ?? '1-3 business days';
      notifyListeners();
    } catch (e) {
      print("Error calculating shipping fee: $e");
    }
  }

  void selectAddress(ShippingAddress address, List<CheckoutCartItem> items) {
    _selectedAddress = address;
    // When a new address is selected, recalculate the shipping fee.
    calculateShippingFee(items);
    notifyListeners();
  }

  // THE FIX: This new method implements the correct 2-step checkout flow.
  Future<Map<String, dynamic>> placeOrderAndInitializePayment(
      List<CheckoutCartItem> items) async {
    final token = _auth.token;
    if (token == null) {
      return {'success': false, 'message': 'Authentication token is missing.'};
    }
    if (_selectedAddress == null) {
      return {'success': false, 'message': 'Please select a shipping address.'};
    }

    // --- Step 1: Create the Order ---
    final itemsPayload = items
        .map((item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
              'attributes_summary': item.variantDescription,
            })
        .toList();

    final newOrderId = await _orderService.createOrder(
      shippingAddressId: _selectedAddress!.id,
      items: itemsPayload,
      token: token,
    );

    if (newOrderId == null) {
      return {'success': false, 'message': 'Failed to create your order.'};
    }

    // --- Step 2: Initialize Payment with the new Order ID ---
    return await _checkoutService.initializePayment(
      orderId: newOrderId,
      token: token,
    );
  }
}
