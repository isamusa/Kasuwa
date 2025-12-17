import 'package:flutter/material.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:kasuwa/services/cart_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/checkout_screen.dart'; // Required for CheckoutCartItem

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${AppConfig.fileBaseUrl}/$path';
}

// Data Model for Cart Items
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

  // Getter alias to match UI code if it uses 'productImage'
  String get productImage => imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>?;

    String imgUrl = 'https://placehold.co/400/purple/white?text=Kasuwa';
    if (images != null && images.isNotEmpty) {
      imgUrl = storageUrl(images[0]['image_url']);
    }

    // Logic: Get price from variant if it exists, otherwise from product
    final variant = json['variant'];
    final priceString = (variant?['sale_price'] ?? variant?['price']) ??
        (product['sale_price'] ?? product['price'])?.toString() ??
        '0.0';

    // Logic: Build variant description
    String? variantDesc;
    if (variant != null && variant['attribute_options'] != null) {
      final options = (variant['attribute_options'] as List)
          .map((opt) => '${opt['attribute']['name']}: ${opt['value']}')
          .join(', ');
      variantDesc = options;
    }

    return CartItem(
      id: json['id'],
      productId: product['id'],
      productName: product['name'] ?? 'No Name',
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

  // Public Getters
  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Total Price for UI
  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Convert to Checkout Format
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
    // If user logs out, clear cart
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
      _error = e.toString();
      // Keep old items on error or empty? Usually better to keep old or show error
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- Add to Cart Methods ---

  Future<void> addVariantToCart(int variantId, int quantity) async {
    // Optimistic Update (Optional) or just wait for server
    final success = await _cartService.addVariantToCart(
        variantId: variantId, quantity: quantity, token: _auth.token);
    if (success) {
      await fetchCart();
    }
  }

  Future<void> addProductToCart(int productId, int quantity) async {
    final success = await _cartService.addProductToCart(
        productId: productId, quantity: quantity, token: _auth.token);
    if (success) {
      await fetchCart();
    }
  }

  // --- Modification Methods matching UI aliases ---

  Future<void> updateCartItemQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) {
      await removeCartItem(cartItemId);
      return;
    }

    // 1. Optimistic Update
    final index = _items.indexWhere((item) => item.id == cartItemId);
    int oldQuantity = 0;
    if (index != -1) {
      oldQuantity = _items[index].quantity;
      _items[index].quantity = quantity;
      notifyListeners(); // Immediate UI update
    }

    // 2. Server Call
    final success =
        await _cartService.updateQuantity(cartItemId, quantity, _auth.token);

    // 3. Rollback if failed
    if (!success && index != -1) {
      _items[index].quantity = oldQuantity;
      notifyListeners();
    } else if (success) {
      // Optional: fetchCart() to be perfectly synced, or trust the optimistic update
    }
  }

  Future<void> removeCartItem(int cartItemId) async {
    // 1. Optimistic Remove
    final existingIndex = _items.indexWhere((i) => i.id == cartItemId);
    CartItem? removedItem;
    if (existingIndex != -1) {
      removedItem = _items[existingIndex];
      _items.removeAt(existingIndex);
      notifyListeners();
    }

    // 2. Server Call
    final success = await _cartService.removeItem(cartItemId, _auth.token);

    // 3. Rollback
    if (!success && removedItem != null) {
      _items.insert(existingIndex, removedItem);
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    // 1. Optimistic Clear
    final oldItems = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();

    // 2. Server Call (Assuming service has this method, if not, remove one by one or ignore)
    // If your API doesn't have a 'clear' endpoint, you might need to loop remove
    // For now, we assume simple local clear or implementation needed in service.
    // If strictly no endpoint, we might just clear local state.

    // Example loop remove if no endpoint:
    /*
    for (var item in oldItems) {
      await _cartService.removeItem(item.id, _auth.token);
    }
    */
  }

  void clearLocal() {
    _items = [];
    _hasFetchedData = false;
    _error = null;
    notifyListeners();
  }
}
