import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:kasuwa/services/attribute_service.dart';
import 'package:kasuwa/services/product_service.dart';

// --- ENHANCEMENT: A helper class to hold all controllers for a single variant ---
class UIVariantController {
  final TextEditingController priceController;
  final TextEditingController salePriceController;
  final TextEditingController stockController;
  final List<AttributeOption> options;

  UIVariantController({required this.options})
      : priceController = TextEditingController(text: '0'),
        salePriceController = TextEditingController(),
        stockController = TextEditingController(text: '0');

  void dispose() {
    priceController.dispose();
    salePriceController.dispose();
    stockController.dispose();
  }
}

class AddProductProvider with ChangeNotifier {
  final AttributeService _attributeService = AttributeService();
  final ProductService _productService = ProductService();
  final CategoryProvider _categoryProvider;

  // --- ENHANCEMENT: All controllers are now managed in the provider ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController simplePriceController = TextEditingController();
  final TextEditingController simpleSalePriceController =
      TextEditingController();
  final TextEditingController simpleStockController = TextEditingController();

  List<ProductAttribute> _availableAttributes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _validationErrors;

  List<XFile> _pickedImages = [];
  String? _selectedCategoryId;
  Map<int, Set<int>> _selectedOptions = {};

  // --- ENHANCEMENT: Manage a list of controllers for variants ---
  List<UIVariantController> _variantControllers = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<ProductAttribute> get availableAttributes => _availableAttributes;
  List<XFile> get pickedImages => _pickedImages;
  Map<int, Set<int>> get selectedOptions => _selectedOptions;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get error => _error;
  Map<String, dynamic>? get validationErrors => _validationErrors;
  List<MainCategory> get categories => _categoryProvider.mainCategories;
  List<UIVariantController> get variantControllers => _variantControllers;

  AddProductProvider(this._categoryProvider) {
    _fetchAttributes();
  }

  // --- ENHANCEMENT: Properly dispose all controllers ---
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    simplePriceController.dispose();
    simpleSalePriceController.dispose();
    simpleStockController.dispose();
    for (var controller in _variantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAttributes() async {
    try {
      _availableAttributes = await _attributeService.getAttributes();
    } catch (e) {
      _error = "Failed to load attributes.";
    }
    _isLoading = false;
    notifyListeners();
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

  void _generateVariants() {
    if (_selectedOptions.isEmpty) {
      // Clear and dispose old controllers
      for (var controller in _variantControllers) {
        controller.dispose();
      }
      _variantControllers = [];
      return;
    }

    final List<List<AttributeOption>> optionsForCartesian =
        _selectedOptions.entries.map((entry) {
      final attribute =
          _availableAttributes.firstWhere((attr) => attr.id == entry.key);
      return entry.value
          .map((optionId) =>
              attribute.options.firstWhere((opt) => opt.id == optionId))
          .toList();
    }).toList();

    final cartesianProduct = _cartesianProduct(optionsForCartesian);

    // --- ENHANCEMENT: Smartly create/dispose/reuse controllers ---
    final newControllers = <UIVariantController>[];
    final existingControllers = {
      for (var vc in _variantControllers)
        vc.options.map((o) => o.id).join('-'): vc
    };

    for (var combo in cartesianProduct) {
      final key = combo.map((o) => o.id).join('-');
      if (existingControllers.containsKey(key)) {
        newControllers.add(existingControllers[key]!);
        existingControllers.remove(key);
      } else {
        newControllers.add(UIVariantController(options: combo));
      }
    }

    // Dispose controllers that are no longer needed
    for (var oldController in existingControllers.values) {
      oldController.dispose();
    }

    _variantControllers = newControllers;
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final List<XFile> selectedImages =
        await picker.pickMultiImage(imageQuality: 80);
    if (selectedImages.isNotEmpty) {
      _pickedImages.addAll(selectedImages);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _pickedImages.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitProduct() async {
    if (_selectedCategoryId == null || _pickedImages.isEmpty) {
      _error = "A category and at least one image are required.";
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _validationErrors = null;
    _error = null;
    notifyListeners();

    List<Map<String, dynamic>>? variantsData;
    String? simplePrice;
    String? simpleSalePrice;
    String? simpleStock;
    if (variantControllers.isNotEmpty) {
      // This is a product with variants
      variantsData = variantControllers.map((vc) {
        final salePrice = vc.salePriceController.text;
        return {
          'price': vc.priceController.text,
          'sale_price': (salePrice.isNotEmpty) ? salePrice : null,
          'stock_quantity': vc.stockController.text,
          'options': vc.options.map((opt) => opt.id).toList(),
        };
      }).toList();
    } else {
      // This is a simple product
      simplePrice = simplePriceController.text;
      simpleSalePrice = simpleSalePriceController.text;
      simpleStock = simpleStockController.text;
    }

    // Call the service with the correctly prepared data
    final result = await _productService.createProduct(
      name: nameController.text,
      description: descriptionController.text,
      categoryId: _selectedCategoryId!,
      images: _pickedImages.map((xfile) => File(xfile.path)).toList(),
      variants: variantsData,
      price: simplePrice,
      salePrice: simpleSalePrice,
      stockQuantity: simpleStock,
    );

    _isSubmitting = false;

    if (result['success'] == true) {
      // Don't reset state here, let the UI pop
      notifyListeners();
      return true;
    } else {
      if (result.containsKey('errors')) {
        _validationErrors = result['errors'];
      }
      _error = result['message'] ?? 'An unknown error occurred.';
      notifyListeners();
      return false;
    }
  }

  // Helper for generating variants
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
}
