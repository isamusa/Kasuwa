import 'package:flutter/material.dart';
import 'package:kasuwa/services/cart_service.dart';
import 'package:kasuwa/config/app_config.dart'; // Import this
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String imageUrl;
  final double price;
  int quantity;
  final String? variantDescription;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.variantDescription,
  });

  String get productImage => imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>?;

    // FIX: Use AppConfig for robust image handling
    String imgUrl = AppConfig.getFullImageUrl(null);
    if (images != null && images.isNotEmpty) {
      imgUrl = AppConfig.getFullImageUrl(images[0]['image_url']);
    }

    final variant = json['variant'];
    final priceString = (variant?['sale_price'] ?? variant?['price']) ??
        (product['sale_price'] ?? product['price'])?.toString() ??
        '0.0';

    String? variantDesc;
    if (variant != null && variant['attribute_options'] != null) {
      try {
        variantDesc = (variant['attribute_options'] as List).map((opt) {
          final name = opt['attribute']?['name'] ?? 'Option';
          final val = opt['value'] ?? '';
          return '$name: $val';
        }).join(', ');
      } catch (e) {
        variantDesc = "Variant Selected";
      }
    }

    return CartItem(
      id: json['id'],
      productId: product['id'] ?? 0,
      productName: product['name'] ?? 'Unknown Product',
      price: double.tryParse(priceString.toString()) ?? 0.0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      imageUrl: imgUrl,
      variantDescription: variantDesc,
    );
  }
}

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final AuthProvider _auth;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedData = false;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  List<CheckoutCartItem> get checkoutItems {
    return _items
        .map((item) => CheckoutCartItem(
              productId: item.productId,
              name: item.productName,
              imageUrl: item.imageUrl,
              price: item.price,
              quantity: item.quantity,
              variantDescription: item.variantDescription,
            ))
        .toList();
  }

  CartProvider(this._auth);

  void update(AuthProvider auth) {
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchCart();
    }
    if (!auth.isAuthenticated && _hasFetchedData) {
      clearLocal();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _hasFetchedData = true;
    notifyListeners();
    try {
      final cartData = await _cartService.getCart(_auth.token);
      _items = cartData.map((itemData) => CartItem.fromJson(itemData)).toList();
      _error = null;
    } catch (e) {
      print("Cart Fetch Error: $e");
      _error = "Could not load cart";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVariantToCart(int variantId, int quantity) async {
    final success = await _cartService.addVariantToCart(
        variantId: variantId, quantity: quantity, token: _auth.token);
    if (success) await fetchCart();
  }

  Future<void> addProductToCart(int productId, int quantity) async {
    final success = await _cartService.addProductToCart(
        productId: productId, quantity: quantity, token: _auth.token);
    if (success) await fetchCart();
  }

  Future<void> removeCartItem(int cartItemId) async {
    final existingIndex = _items.indexWhere((i) => i.id == cartItemId);
    if (existingIndex == -1) return;

    CartItem removedItem = _items[existingIndex];
    _items.removeAt(existingIndex);
    notifyListeners();

    final success = await _cartService.removeItem(cartItemId, _auth.token);
    if (!success) {
      _items.insert(existingIndex, removedItem);
      notifyListeners();
    }
  }

  Future<void> updateCartItemQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) {
      await removeCartItem(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    int oldQuantity = _items[index].quantity;
    _items[index].quantity = quantity;
    notifyListeners();

    final success =
        await _cartService.updateQuantity(cartItemId, quantity, _auth.token);
    if (!success) {
      _items[index].quantity = oldQuantity;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    final oldItems = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();

    try {
      final deleteFutures = oldItems
          .map((item) => _cartService.removeItem(item.id, _auth.token))
          .toList();
      await Future.wait(deleteFutures);
    } catch (e) {
      // If mass delete fails, force a refresh to sync with server
      await fetchCart();
    }
  }

  void clearLocal() {
    _items = [];
    _hasFetchedData = false;
    _error = null;
    notifyListeners();
  }
}
