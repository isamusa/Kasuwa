import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/services/attribute_service.dart';
import 'package:kasuwa/services/product_service.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:kasuwa/services/category_service.dart';

// A helper class to manage variant data in the UI
class UIVariant {
  final List<AttributeOption> options;
  String price;
  String? salePrice;
  String stock;

  UIVariant(
      {required this.options,
      this.price = '0',
      this.salePrice,
      this.stock = '0'});
}

class EditProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final AttributeService _attributeService = AttributeService();

  ProductDetail? _product;
  List<ProductAttribute> _availableAttributes = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  Map<int, Set<int>> _selectedOptions = {};
  List<UIVariant> _generatedVariants = [];

  // Public Getters
  ProductDetail? get product => _product;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? _validationErrors;
  Map<String, dynamic>? get validationErrors => _validationErrors;

  bool get isSubmitting => _isSubmitting;
  List<ProductAttribute> get availableAttributes => _availableAttributes;
  List<UIVariant> get generatedVariants => _generatedVariants;
  Map<int, Set<int>> get selectedOptions => _selectedOptions;
  String? _selectedCategoryId;

  String? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadProductForEdit(int productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _productService.getProductDetails(productId),
        _attributeService.getAttributes(),
      ]);

      _product = results[0] as ProductDetail?;
      _availableAttributes = results[1] as List<ProductAttribute>;

      if (_product != null) {
        _prepopulateState();
      } else {
        _error = "Product not found.";
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _prepopulateState() {
    _selectedCategoryId = _product!.category.id.toString();

    for (var attribute in _product!.attributes) {
      _selectedOptions[attribute.id] =
          attribute.options.map((opt) => opt.id).toSet();
    }

    _generatedVariants = _product!.variants.map((variant) {
      return UIVariant(
        options: variant.attributeOptions,
        price: variant.price.toStringAsFixed(0),
        salePrice: variant.salePrice?.toStringAsFixed(0),
        stock: variant.stockQuantity.toString(),
      );
    }).toList();
  }

  void onCategoryChanged(String? newCategoryId) {
    _selectedCategoryId = newCategoryId;
    notifyListeners();
  }

  void toggleOption(int attributeId, int optionId) {
    if (_selectedOptions.containsKey(attributeId)) {
      if (_selectedOptions[attributeId]!.contains(optionId)) {
        _selectedOptions[attributeId]!.remove(optionId);
        if (_selectedOptions[attributeId]!.isEmpty) {
          _selectedOptions.remove(attributeId);
        }
      } else {
        _selectedOptions[attributeId]!.add(optionId);
      }
    } else {
      _selectedOptions[attributeId] = {optionId};
    }
    _generateVariants();
    notifyListeners();
  }

  List<List<T>> _cartesianProduct<T>(List<List<T>> lists) {
    if (lists.isEmpty) return [[]];
    List<List<T>> result = [[]];
    for (final list in lists) {
      List<List<T>> newResult = [];
      for (final element in list) {
        for (final existingList in result) {
          newResult.add([...existingList, element]);
        }
      }
      result = newResult;
    }
    return result;
  }

  void _generateVariants() {
    if (_selectedOptions.isEmpty) {
      _generatedVariants = [];
      return;
    }

    final optionsForCartesian = _selectedOptions.values.map((idSet) {
      final attributeId = _selectedOptions.entries
          .firstWhere((entry) => entry.value == idSet)
          .key;
      final attribute =
          _availableAttributes.firstWhere((attr) => attr.id == attributeId);
      return idSet
          .map((id) => attribute.options.firstWhere((opt) => opt.id == id))
          .toList();
    }).toList();

    final cartesianProduct = _cartesianProduct(optionsForCartesian);

    _generatedVariants = cartesianProduct
        .map((combo) => UIVariant(options: List<AttributeOption>.from(combo)))
        .toList();
  }

  void updateVariantPrice(int index, String price) {
    if (index < _generatedVariants.length)
      _generatedVariants[index].price = price;
  }

  void updateVariantSalePrice(int index, String salePrice) {
    if (index < _generatedVariants.length)
      _generatedVariants[index].salePrice = salePrice;
  }

  void updateVariantStock(int index, String stock) {
    if (index < _generatedVariants.length)
      _generatedVariants[index].stock = stock;
  }

  /// **REFACTORED:** This method now uses the single, consolidated `updateProduct` service method.
  Future<bool> submitUpdate({
    required String name,
    required String description,
    // These are only used if the product has no variants
    String? price,
    String? salePrice,
    String? stockQuantity,
  }) async {
    _validationErrors = null;
    _isSubmitting = true;
    notifyListeners();

    // Prepare variants data if they exist
    List<Map<String, dynamic>>? variantsData;
    if (_generatedVariants.isNotEmpty) {
      variantsData = _generatedVariants.map((v) {
        return {
          'price': v.price,
          'sale_price': (v.salePrice != null && v.salePrice!.isNotEmpty)
              ? v.salePrice
              : null,
          'stock_quantity': v.stock,
          'options': v.options.map((opt) => opt.id).toList(),
        };
      }).toList();
    }

    // Call the single, consolidated update method from the service
    final result = await _productService.updateProduct(
      productId: _product!.id,
      name: name,
      description: description,
      categoryId: _selectedCategoryId!,
      // Pass either variant data OR simple product data
      variants: variantsData,
      price: variantsData == null ? price : null,
      salePrice: variantsData == null ? salePrice : null,
      stockQuantity: variantsData == null ? stockQuantity : null,
    );

    _isSubmitting = false;

    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      if (result.containsKey('errors')) {
        _validationErrors = result['errors'];
      }
      notifyListeners();
      return false;
    }
  }
}
