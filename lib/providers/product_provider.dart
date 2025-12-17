import 'package:flutter/material.dart';
import 'package:kasuwa/services/product_service.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthProvider _auth;
  final CheckoutProvider _checkout;

  ProductDetail? _product;
  bool _isLoadingPage = false;
  bool _isBackgroundLoading = false;
  String? _error;

  double? _shippingFee;
  String? _estimatedDelivery;

  Map<int, int> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  ProductDetail? get product => _product;
  bool get isLoading => _isLoadingPage;
  bool get isBackgroundLoading => _isBackgroundLoading;
  String? get error => _error;

  ProductVariant? get selectedVariant => _selectedVariant;
  int get quantity => _quantity;
  Map<int, int> get selectedOptions => _selectedOptions;
  double? get shippingFee => _shippingFee;
  String? get estimatedDelivery => _estimatedDelivery;
  ShippingAddress? get defaultAddress => _checkout.selectedAddress;

  ProductProvider(this._auth, this._checkout);

  // FIX 1: New helper to determine the real maximum stock allowed
  int get maxStock {
    if (_product == null) return 0;

    // Case A: Simple Product (No attributes)
    if (_product!.attributes.isEmpty) {
      return _product!.stockQuantity ?? 0;
    }

    // Case B: Variable Product (Has attributes)
    // If no variant is selected yet, user can't buy, so max is 0
    return _selectedVariant?.stockQuantity ?? 0;
  }

  bool get canAddToCart {
    if (_isBackgroundLoading) return false;
    // We can simply check if we have stock available to add
    return maxStock > 0;
  }

  // ... (fetchProductDetails and getShippingFee remain exactly the same) ...
  // [Paste the fetchProductDetails and getShippingFee code from previous step here if re-copying file]
  void update(AuthProvider auth, CheckoutProvider checkout) {}

  Future<void> fetchProductDetails(int productId,
      {HomeProduct? initialData}) async {
    // ... (Keep existing implementation) ...
    if (initialData != null) {
      _product = ProductDetail.fromHomeProduct(initialData);
      _isLoadingPage = false;
      _isBackgroundLoading = true;
    } else {
      _isLoadingPage = true;
      _isBackgroundLoading = false;
    }
    _error = null;
    notifyListeners();

    try {
      final List<Future> tasks = [];
      tasks.add(
          _productService.getProductDetails(productId).then((detailedProduct) {
        _product = detailedProduct;
        if (_product != null &&
            _product!.attributes.isEmpty &&
            _product!.variants.isNotEmpty) {
          _selectedVariant = _product!.variants.first;
        }
        notifyListeners();
      }));

      if (_auth.isAuthenticated) {
        tasks.add(() async {
          if (_checkout.selectedAddress == null) {
            await _checkout.fetchAddresses(items: []);
          }
          if (_checkout.selectedAddress != null) {
            await getShippingFee(productId, _checkout.selectedAddress!.id);
          }
        }());
      }
      await Future.wait(tasks);
    } catch (e) {
      if (_product == null)
        _error = "An error occurred while loading the product.";
      print("Product Fetch Error: $e");
    } finally {
      _isLoadingPage = false;
      _isBackgroundLoading = false;
      notifyListeners();
    }
  }

  Future<void> getShippingFee(int productId, int addressId) async {
    // ... (Keep existing implementation) ...
    final token = _auth.token;
    if (token == null) return;
    try {
      _shippingFee = null;
      notifyListeners();
      final result =
          await _productService.getShippingFee(token, productId, addressId);
      _shippingFee = double.tryParse(result['shipping_fee'].toString());
      _estimatedDelivery = result['estimated_delivery'];
    } catch (e) {
      _shippingFee = null;
      _estimatedDelivery = null;
    }
    notifyListeners();
  }

  // FIX 2: Update setQuantity to respect maxStock
  void setQuantity(int newQuantity) {
    if (newQuantity > 0 && newQuantity <= maxStock) {
      _quantity = newQuantity;
      notifyListeners();
    } else if (newQuantity > maxStock) {
      // Optional: Shake UI or show message?
      // For now, we just clamp it silently or do nothing.
      _quantity = maxStock;
      notifyListeners();
    }
  }

  void selectOption(int attributeId, int? optionId) {
    if (optionId == null) {
      _selectedOptions.remove(attributeId);
    } else {
      _selectedOptions[attributeId] = optionId;
    }
    _updateSelectedVariant();
    notifyListeners();
  }

  void _updateSelectedVariant() {
    if (_product == null || _product!.attributes.isEmpty) {
      _selectedVariant = _product?.variants.first;
      // FIX 3: Reset quantity if it exceeds new variant's stock
      if (_selectedVariant != null &&
          _quantity > _selectedVariant!.stockQuantity) {
        _quantity = 1;
      }
      return;
    }

    if (_selectedOptions.length != _product!.attributes.length) {
      _selectedVariant = null;
      return;
    }

    final selectedOptionIds = _selectedOptions.values.toSet();
    bool found = false;
    for (var variant in _product!.variants) {
      final variantOptionIds =
          variant.attributeOptions.map((opt) => opt.id).toSet();
      if (variantOptionIds.length == selectedOptionIds.length &&
          variantOptionIds.every(selectedOptionIds.contains)) {
        _selectedVariant = variant;
        found = true;
        break;
      }
    }

    if (!found) {
      _selectedVariant = null;
    } else {
      // FIX 3: Reset quantity if it exceeds new variant's stock
      if (_quantity > _selectedVariant!.stockQuantity) {
        _quantity = 1;
      }
    }
  }
}
