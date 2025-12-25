import 'package:flutter/material.dart';
import 'package:kasuwa/services/checkout_service.dart';
import 'package:kasuwa/services/order_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/models/checkout_models.dart';

// Export these so other files importing this provider don't break immediately
export 'package:kasuwa/models/checkout_models.dart';

class CheckoutProvider with ChangeNotifier {
  final CheckoutService _checkoutService = CheckoutService();
  final OrderService _orderService = OrderService();
  final AuthProvider _auth;

  List<ShippingAddress> _addresses = [];
  ShippingAddress? _selectedAddress;
  bool _isLoading = false;
  String? _error;
  double _shippingFee = 1500.00;
  String _estimatedDelivery = "1-3 business days";
  int? _createdOrderId;

  List<ShippingAddress> get addresses => _addresses;
  ShippingAddress? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get shippingFee => _shippingFee;
  String get estimatedDelivery => _estimatedDelivery;

  CheckoutProvider(this._auth);

  void update(AuthProvider auth) {}

  Future<void> fetchAddresses({List<CheckoutCartItem>? items}) async {
    _isLoading = true;
    _createdOrderId = null;
    notifyListeners();
    try {
      final token = _auth.token;
      if (token != null) {
        _addresses = await _checkoutService.getShippingAddresses(token);
        if (_addresses.isNotEmpty) {
          _selectedAddress = _addresses.firstWhere((a) => a.isDefault,
              orElse: () => _addresses.first);
          if (items != null && items.isNotEmpty) {
            await calculateShippingFee(items);
          }
        }
      }
      _error = null;
    } catch (e) {
      _error = "Could not load addresses.";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> calculateShippingFee(List<CheckoutCartItem> items) async {
    final token = _auth.token;
    if (token == null || _selectedAddress == null || items.isEmpty) return;

    try {
      final result = await _checkoutService.getShippingFee(
          token, _selectedAddress!.id, items);

      _shippingFee =
          double.tryParse(result['shipping_fee']?.toString() ?? '1500.0') ??
              1500.0;
      _estimatedDelivery = result['estimated_delivery'] ?? '1-3 business days';
      notifyListeners();
    } catch (e) {
      print("Fee calc error: $e");
    }
  }

  void selectAddress(ShippingAddress address, List<CheckoutCartItem> items) {
    _selectedAddress = address;
    _createdOrderId = null;
    calculateShippingFee(items);
    notifyListeners();
  }

  void resetOrderTracking() {
    _createdOrderId = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> placeOrderAndInitializePayment(
      List<CheckoutCartItem> items) async {
    final token = _auth.token;
    if (token == null) return {'success': false, 'message': 'Auth failed.'};
    if (_selectedAddress == null)
      return {'success': false, 'message': 'Select address.'};

    if (_createdOrderId != null) {
      return await _checkoutService.retryOrderPayment(
        orderId: _createdOrderId!,
        token: token,
      );
    }

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
      shippingFee: _shippingFee,
      token: token,
    );

    if (newOrderId == null) {
      return {'success': false, 'message': 'Failed to create order.'};
    }

    _createdOrderId = newOrderId;

    return await _checkoutService.initializePayment(
      orderId: newOrderId,
      token: token,
    );
  }
}
