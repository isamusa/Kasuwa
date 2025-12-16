import 'package:flutter/material.dart';
import 'package:kasuwa/services/cart_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/auth_provider.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
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

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty
        ? storageUrl(images[0]['image_url'])
        : 'https://placehold.co/400/purple/white?text=Kasuwa';

    // THE FIX: Get price from variant if it exists, otherwise from product
    final variant = json['variant'];
    final priceString = (variant?['sale_price'] ?? variant?['price']) ??
        (product['sale_price'] ?? product['price'])?.toString() ??
        '0.0';

    // THE FIX: Build variant description from variant if it exists
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
      price: double.tryParse(priceString) ?? 0.0,
      quantity: json['quantity'],
      imageUrl: imageUrl,
      variantDescription: variantDesc,
    );
  }
}

// The Enhanced Cart Provider
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final AuthProvider _auth;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedData = false;
  Set<int> _selectedItemIds = {};
  int? _updatingItemId;

  // Public Getters
  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<int> get selectedItemIds => _selectedItemIds;
  int? get updatingItemId => _updatingItemId;

  List<CartItem> get selectedItems {
    return _items.where((item) => _selectedItemIds.contains(item.id)).toList();
  }

  double get selectedItemsTotalPrice {
    return selectedItems.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  bool get areAllItemsSelected {
    if (_items.isEmpty) return false;
    return _selectedItemIds.length == _items.length;
  }

  CartProvider(this._auth);

  void update(AuthProvider auth) {
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchCart();
    }
    if (!auth.isAuthenticated && _hasFetchedData) {
      clear();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _hasFetchedData = true;
    notifyListeners();
    try {
      final cartData = await _cartService.getCart(_auth.token);
      _items = cartData.map((itemData) => CartItem.fromJson(itemData)).toList();
      _selectedItemIds.clear();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Method for products WITH variants
  Future<void> addVariantToCart(int variantId, int quantity) async {
    final success = await _cartService.addVariantToCart(
        variantId: variantId, quantity: quantity, token: _auth.token);
    if (success) {
      await fetchCart(); // Refresh cart from server
    }
  }

  // THE FIX: Add new method for simple products
  Future<void> addProductToCart(int productId, int quantity) async {
    final success = await _cartService.addProductToCart(
        productId: productId, quantity: quantity, token: _auth.token);
    if (success) {
      await fetchCart(); // Refresh cart from server
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) {
      await removeItem(cartItemId);
      return;
    }
    _updatingItemId = cartItemId;
    notifyListeners();

    final success =
        await _cartService.updateQuantity(cartItemId, quantity, _auth.token);
    if (success) {
      final index = _items.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        _items[index].quantity = quantity;
      }
    }
    _updatingItemId = null;
    notifyListeners();
  }

  Future<void> removeItem(int cartItemId) async {
    final success = await _cartService.removeItem(cartItemId, _auth.token);
    if (success) {
      _items.removeWhere((item) => item.id == cartItemId);
      _selectedItemIds.remove(cartItemId);
      notifyListeners();
    }
  }

  void toggleItemSelected(int cartItemId) {
    if (_selectedItemIds.contains(cartItemId)) {
      _selectedItemIds.remove(cartItemId);
    } else {
      _selectedItemIds.add(cartItemId);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool select) {
    if (select) {
      _selectedItemIds = _items.map((item) => item.id).toSet();
    } else {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  void clear() {
    _items = [];
    _hasFetchedData = false;
    _selectedItemIds.clear();
    _error = null;
    notifyListeners();
  }
}
