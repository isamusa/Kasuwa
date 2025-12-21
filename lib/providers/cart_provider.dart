import 'package:flutter/material.dart';
import 'package:kasuwa/services/cart_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/checkout_screen.dart'; // Required for CheckoutCartItem
import 'package:kasuwa/providers/checkout_provider.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }
  return '${AppConfig.baseUrl}/storage/$path';
}

// --- Data Model for Cart Items ---
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

  // Getter alias to match UI code
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

    // Logic: Build variant description safely
    String? variantDesc;
    if (variant != null && variant['attribute_options'] != null) {
      try {
        final options = (variant['attribute_options'] as List).map((opt) {
          final name = opt['attribute']?['name'] ?? 'Option';
          final val = opt['value'] ?? '';
          return '$name: $val';
        }).join(', ');
        if (options.isNotEmpty) variantDesc = options;
      } catch (e) {
        // Fallback if structure differs slightly
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
    // If user logs out, clear local cart state
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

  // --- Add to Cart Methods ---

  Future<void> addVariantToCart(int variantId, int quantity) async {
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

  // --- DELETE FEATURE (Fixed) ---

  Future<void> removeCartItem(int cartItemId) async {
    // 1. Snapshot State for Rollback
    final existingIndex = _items.indexWhere((i) => i.id == cartItemId);
    CartItem? removedItem;

    if (existingIndex != -1) {
      removedItem = _items[existingIndex];
      // Optimistic Remove: Update UI immediately
      _items.removeAt(existingIndex);
      notifyListeners();
    } else {
      return; // Item doesn't exist locally
    }

    try {
      // 2. Server Call
      final success = await _cartService.removeItem(cartItemId, _auth.token);

      // 3. Rollback if server fails
      if (!success) {
        _items.insert(existingIndex, removedItem!);
        notifyListeners();
      }
    } catch (e) {
      // On Exception (Network error), rollback
      _items.insert(existingIndex, removedItem!);
      notifyListeners();
      print("Remove Item Error: $e");
    }
  }

  // --- UPDATE QUANTITY ---

  Future<void> updateCartItemQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) {
      await removeCartItem(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    int oldQuantity = 0;

    if (index != -1) {
      oldQuantity = _items[index].quantity;
      // Optimistic Update
      _items[index].quantity = quantity;
      notifyListeners();
    }

    try {
      final success =
          await _cartService.updateQuantity(cartItemId, quantity, _auth.token);

      if (!success && index != -1) {
        // Rollback
        _items[index].quantity = oldQuantity;
        notifyListeners();
      }
    } catch (e) {
      if (index != -1) {
        _items[index].quantity = oldQuantity;
        notifyListeners();
      }
    }
  }

  // --- CLEAR CART (Implemented) ---

  Future<void> clearCart() async {
    // 1. Snapshot for rollback
    final oldItems = List<CartItem>.from(_items);

    // 2. Optimistic Clear
    _items.clear();
    notifyListeners();

    try {
      // 3. Server Call
      // Since most APIs don't have a "delete all" endpoint, we loop delete.
      // Ideally, your backend should have a DELETE /cart endpoint.
      // Using Future.wait to delete parallelly for speed.

      final deleteFutures = oldItems
          .map((item) => _cartService.removeItem(item.id, _auth.token))
          .toList();

      final results = await Future.wait(deleteFutures);

      // If any deletion failed, we re-fetch to ensure state sync
      if (results.any((success) => !success)) {
        await fetchCart();
      }
    } catch (e) {
      // On critical failure, restore items or re-fetch
      _items = oldItems;
      notifyListeners();
      print("Clear Cart Error: $e");
    }
  }

  void clearLocal() {
    _items = [];
    _hasFetchedData = false;
    _error = null;
    notifyListeners();
  }
}
