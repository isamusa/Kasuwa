import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:kasuwa/services/category_service.dart';
import 'package:kasuwa/services/product_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/providers/dashboard_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/theme/app_theme.dart';

// --- The Main UI Screen ---
class EditProductScreen extends StatefulWidget {
  final int productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  ProductDetail? _product;
  List<MainCategory> _categories = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController; // For simple products
  late TextEditingController _salePriceController; // For simple products
  late TextEditingController _stockController; // For simple products

  String? _selectedCategoryId;

  // Variant Controllers
  final List<TextEditingController> _variantPriceControllers = [];
  final List<TextEditingController> _variantSalePriceControllers = [];
  final List<TextEditingController> _variantStockControllers = [];

  // Image State
  final List<File> _newImages = [];
  final List<int> _deletedImageIds = []; // To track deleted images
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _salePriceController = TextEditingController();
    _stockController = TextEditingController();
    _fetchProductAndCategories();
  }

  Future<void> _fetchProductAndCategories() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getProductDetails(widget.productId),
        _categoryService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _product = results[0] as ProductDetail?;
          _categories = results[1] as List<MainCategory>;

          if (_product != null) {
            _nameController.text = _product!.name;
            _descriptionController.text = _product!.description;
            _selectedCategoryId = _product!.category.id.toString();

            if (_product!.variants.isNotEmpty) {
              // This part is for products WITH variants, it's correct.
              for (var variant in _product!.variants) {
                _variantPriceControllers.add(TextEditingController(
                    text: variant.price.toStringAsFixed(0)));
                _variantSalePriceControllers.add(TextEditingController(
                    text: variant.salePrice?.toStringAsFixed(0) ?? ''));
                _variantStockControllers.add(TextEditingController(
                    text: variant.stockQuantity.toString()));
              }
            } else {
              // This part is for SIMPLE products. Read from the new top-level fields.
              _priceController.text = _product!.price?.toStringAsFixed(0) ?? '';
              _salePriceController.text =
                  _product!.salePrice?.toStringAsFixed(0) ?? '';
              _stockController.text = _product!.stockQuantity?.toString() ?? '';
            }
          } else {
            _error = "Product not found.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load data. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    for (var controller in _variantPriceControllers) {
      controller.dispose();
    }
    for (var controller in _variantSalePriceControllers) {
      controller.dispose();
    }
    for (var controller in _variantStockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// **FIXED:** This method now uses the consolidated `updateProduct` service call.
  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    List<Map<String, dynamic>>? variantsData;
    // Check if the product was originally a variant-based product
    if (_variantPriceControllers.isNotEmpty) {
      variantsData = [];
      for (int i = 0; i < _product!.variants.length; i++) {
        variantsData.add({
          'id': _product!.variants[i]
              .id, // Important for backend to identify which variant to update
          'price': _variantPriceControllers[i].text,
          'sale_price': _variantSalePriceControllers[i].text,
          'stock_quantity': _variantStockControllers[i].text,
          'options': _product!.variants[i].attributeOptions
              .map((opt) => opt.id)
              .toList(),
        });
      }
    }

    final result = await _productService.updateProduct(
      productId: widget.productId,
      name: _nameController.text,
      description: _descriptionController.text,
      categoryId: _selectedCategoryId!,
      // Pass the appropriate data based on product type
      variants: variantsData,
      price: variantsData == null ? _priceController.text : null,
      salePrice: variantsData == null ? _salePriceController.text : null,
      stockQuantity: variantsData == null ? _stockController.text : null,
      // Pass image data
      newImages: _newImages,
      deletedImageIds: _deletedImageIds,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      final bool success = result['success'] == true;

      if (success) {
        Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboardData();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        final message =
            result['message'] ?? 'Failed to update product. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 85, // Compress image
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColorPrimary,
        elevation: 1,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_product == null) {
      return const Center(child: Text("Product not found."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Core Information'),
            _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.label_outline),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _descriptionController,
                label: 'Product Description',
                icon: Icons.description_outlined,
                maxLines: 5),

            const SizedBox(height: 24),
            _buildSectionHeader('Organization'),
            _buildCategoryDropdown(),

            const SizedBox(height: 24),
            _buildSectionHeader('Product Images'),
            _buildImagePicker(),

            const SizedBox(height: 24),
            _buildSectionHeader('Pricing & Stock'),
            // Show either variant fields or simple product fields
            if (_variantPriceControllers.isNotEmpty)
              _buildVariantList()
            else
              _buildSimpleProductFields(),

            const SizedBox(height: 100), // Padding for bottom nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColorPrimary),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (_product == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Text('Save Changes',
                style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'This field cannot be empty'
          : null,
    );
  }

  Widget _buildCategoryDropdown() {
    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (var mainCategory in _categories) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(mainCategory.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ),
      );
      for (var subCategory in mainCategory.subcategories) {
        dropdownItems.add(DropdownMenuItem<String>(
          value: subCategory.id.toString(),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(subCategory.name, overflow: TextOverflow.ellipsis),
          ),
        ));
      }
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined,
            color: AppTheme.primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedCategoryId,
      hint: const Text('Choose a sub-category'),
      isExpanded: true,
      items: dropdownItems,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategoryId = value);
        }
      },
      validator: (value) =>
          value == null ? 'Please select a sub-category' : null,
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _product!.images.length + _newImages.length + 1,
        itemBuilder: (context, index) {
          // The Add Image Button
          if (index == _product!.images.length + _newImages.length) {
            return _buildAddImageButton();
          }

          // Display Network Images
          if (index < _product!.images.length) {
            final image = _product!.images[index];
            return _buildImageTile(
              image: CachedNetworkImageProvider(image.url),
              onDelete: () {
                setState(() {
                  // Add the ID to the list of images to be deleted on the backend
                  if (image.id != null) {
                    _deletedImageIds.add(image
                        .id!); // Use '!' because you know it's not null here
                  }

                  // Remove from the UI immediately
                  _product!.images.removeAt(index);
                });
              },
            );
          }

          // Display New Local Images
          final newImageIndex = index - _product!.images.length;
          final imageFile = _newImages[newImageIndex];
          return _buildImageTile(
            image: FileImage(imageFile),
            onDelete: () {
              setState(() {
                _newImages.removeAt(newImageIndex);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildImageTile(
      {required ImageProvider image, required VoidCallback onDelete}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppTheme.destructiveColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  // New widget for simple product fields
  Widget _buildSimpleProductFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildVariantField(
                    controller: _priceController, label: 'Price (₦)')),
            const SizedBox(width: 16),
            Expanded(
                child: _buildVariantField(
                    controller: _salePriceController,
                    label: 'Sale Price (₦)',
                    isRequired: false)),
          ],
        ),
        const SizedBox(height: 16),
        _buildVariantField(
            controller: _stockController, label: 'Stock Quantity'),
      ],
    );
  }

  Widget _buildVariantList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _product!.variants.length,
      itemBuilder: (context, index) {
        final variant = _product!.variants[index];
        final variantTitle =
            variant.attributeOptions.map((o) => o.value).join(' / ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(variantTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorPrimary)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedAlignment: Alignment.topLeft,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildVariantField(
                          controller: _variantPriceControllers[index],
                          label: 'Price (₦)')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildVariantField(
                          controller: _variantSalePriceControllers[index],
                          label: 'Sale Price (₦)',
                          isRequired: false)),
                ],
              ),
              const SizedBox(height: 16),
              _buildVariantField(
                  controller: _variantStockControllers[index],
                  label: 'Stock Quantity'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVariantField(
      {required TextEditingController controller,
      required String label,
      bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) {
          return 'Req.';
        }
        return null;
      },
    );
  }
}
