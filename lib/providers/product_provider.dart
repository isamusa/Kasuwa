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
  String? _error;

  double? _shippingFee;
  String? _estimatedDelivery;

  // State management for user selections ---
  Map<int, int> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  // Public getters to access state from the UI
  ProductDetail? get product => _product;
  bool get isLoading => _isLoadingPage;
  String? get error => _error;

  bool _isFetchingDetails = false;
  ProductVariant? get selectedVariant => _selectedVariant;
  int get quantity => _quantity;
  Map<int, int> get selectedOptions => _selectedOptions;
  double? get shippingFee => _shippingFee;
  String? get estimatedDelivery => _estimatedDelivery;
  // Get the default address directly from the CheckoutProvider
  ShippingAddress? get defaultAddress => _checkout.selectedAddress;

  ProductProvider(this._auth, this._checkout);

  // Getter to determine if the buttons should be enabled
  bool get canAddToCart {
    if (_product == null) return false;
    // For simple products, check base stock
    if (_product!.attributes.isEmpty) {
      return (_product!.stockQuantity ?? 0) > 0;
    }
    // For products with variants, check selected variant stock
    return _selectedVariant != null && _selectedVariant!.stockQuantity > 0;
  }

  void update(AuthProvider auth, CheckoutProvider checkout) {
    // No specific update logic needed here for now, but the structure is in place.
  }

  Future<void> fetchProductDetails(int productId,
      {HomeProduct? initialData}) async {
    _isLoadingPage = true;
    notifyListeners();

    try {
      final detailedProduct =
          await _productService.getProductDetails(productId);
      _product = detailedProduct;
      _isFetchingDetails = true;
      // If it's a simple product, set its default variant automatically
      if (_product != null &&
          _product!.attributes.isEmpty &&
          _product!.variants.isNotEmpty) {
        _selectedVariant = _product!.variants.first;
      }
      if (_auth.isAuthenticated) {
        // We can get the default address from the CheckoutProvider, which is already loaded.
        if (_checkout.selectedAddress != null) {
          await getShippingFee(productId, _checkout.selectedAddress!.id);
        }
      }
    } catch (e) {
      _error = "An error occurred while loading the product.";
    }

    _isLoadingPage = false;
    _isFetchingDetails = false;
    notifyListeners();
  }

  Future<void> getShippingFee(int productId, int addressId) async {
    final token = _auth.token;
    if (token == null) return;

    try {
      final result =
          await _productService.getShippingFee(token, productId, addressId);
      _shippingFee = result['shipping_fee'];
      _estimatedDelivery = result['estimated_delivery'];
    } catch (e) {
      _shippingFee = null;
      _estimatedDelivery = null;
    }
    notifyListeners();
  }

  // --- NEW: Methods to update state from the UI ---
  void setQuantity(int newQuantity) {
    if (newQuantity > 0) {
      _quantity = newQuantity;
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
      return;
    }

    if (_selectedOptions.length != _product!.attributes.length) {
      _selectedVariant = null;
      return;
    }

    final selectedOptionIds = _selectedOptions.values.toSet();
    for (var variant in _product!.variants) {
      final variantOptionIds =
          variant.attributeOptions.map((opt) => opt.id).toSet();
      if (variantOptionIds.length == selectedOptionIds.length &&
          variantOptionIds.every(selectedOptionIds.contains)) {
        _selectedVariant = variant;
        return;
      }
    }
    _selectedVariant = null;
  }
}
