import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kasuwa/providers/add_product_provider.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddProductProvider(
        Provider.of<CategoryProvider>(context, listen: false),
      ),
      child: const _AddProductView(),
    );
  }
}

class _AddProductView extends StatefulWidget {
  const _AddProductView();
  @override
  __AddProductViewState createState() => __AddProductViewState();
}

class __AddProductViewState extends State<_AddProductView> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitProduct() async {
    final provider = context.read<AddProductProvider>();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required fields.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final success = await provider.submitProduct();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product created successfully! Pending approval.'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(provider.error ?? 'Failed to create product. Check errors.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      body: _buildBody(provider),
      bottomNavigationBar: _buildSubmitButton(provider),
    );
  }

  Widget _buildBody(AddProductProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.availableAttributes.isEmpty) {
      return Center(child: Text("Error: ${provider.error}"));
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Core Information',
              children: [
                _buildTextField(
                  controller: provider.nameController,
                  label: 'Product Name',
                  icon: Icons.label_outline,
                  // --- ENHANCEMENT: Display server validation error ---
                  errorText: provider.validationErrors?['name']?[0],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: provider.descriptionController,
                  label: 'Product Description',
                  icon: Icons.description_outlined,
                  maxLines: 5,
                  errorText: provider.validationErrors?['description']?[0],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Organization',
              children: [_buildCategoryDropdown(provider)],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Product Images',
              children: [_buildImagePicker(provider)],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Product Attributes',
              children: [_buildAttributeSelection(provider)],
            ),
            const SizedBox(height: 24),
            if (provider.variantControllers.isEmpty)
              _buildSectionCard(
                title: 'Pricing & Inventory',
                children: [_buildSimpleProductFields(provider)],
              )
            else
              _buildSectionCard(
                title: 'Variants Pricing & Stock',
                children: [_buildVariantList(provider)],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleProductFields(AddProductProvider provider) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: provider.simplePriceController,
                label: 'Regular Price (₦)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                errorText: provider.validationErrors?['price']?[0],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: provider.simpleSalePriceController,
                label: 'Sale Price (₦)',
                icon: Icons.local_offer_outlined,
                keyboardType: TextInputType.number,
                isOptional: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.simpleStockController,
          label: 'Stock Quantity',
          icon: Icons.inventory_2_outlined,
          keyboardType: TextInputType.number,
          errorText: provider.validationErrors?['stock_quantity']?[0],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AddProductProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: ElevatedButton(
        onPressed: provider.isSubmitting ? null : _submitProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Text('Add Product',
                style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isOptional = false,
    String? errorText,
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
        errorText: errorText,
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown(AddProductProvider provider) {
    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (var mainCategory in provider.categories) {
      dropdownItems.add(DropdownMenuItem<String>(
          enabled: false,
          child: Text(mainCategory.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor))));
      for (var subCategory in mainCategory.subcategories) {
        dropdownItems.add(DropdownMenuItem<String>(
            value: subCategory.id.toString(),
            child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child:
                    Text(subCategory.name, overflow: TextOverflow.ellipsis))));
      }
    }
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined,
            color: AppTheme.primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: provider.validationErrors?['category_id']?[0],
      ),
      value: provider.selectedCategoryId,
      hint: const Text('Choose a sub-category'),
      isExpanded: true,
      items: dropdownItems,
      onChanged: provider.onCategoryChanged,
      validator: (value) =>
          value == null ? 'Please select a sub-category' : null,
    );
  }

  Widget _buildAttributeSelection(AddProductProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: provider.availableAttributes.map((attribute) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(attribute.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: attribute.options.map((option) {
                  final isSelected = provider.selectedOptions[attribute.id]
                          ?.contains(option.id) ??
                      false;
                  return FilterChip(
                    label: Text(option.value),
                    selected: isSelected,
                    onSelected: (selected) =>
                        provider.toggleOption(attribute.id, option.id),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVariantList(AddProductProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.variantControllers.length,
      itemBuilder: (context, index) {
        final variantController = provider.variantControllers[index];
        final title = variantController.options.map((o) => o.value).join(' / ');
        return Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _buildTextField(
                                controller: variantController.priceController,
                                label: 'Price (₦)',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                controller:
                                    variantController.salePriceController,
                                label: 'Sale Price (₦)',
                                icon: Icons.local_offer_outlined,
                                keyboardType: TextInputType.number,
                                isOptional: true))
                      ]),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: variantController.stockController,
                          label: 'Stock Quantity',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number),
                    ])));
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Widget _buildImagePicker(AddProductProvider provider) {
    return Column(
      children: [
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: provider.pickedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.pickedImages.length) {
                return _buildAddImageButton(provider);
              }
              return _buildImagePreview(provider, index);
            }),
        if (provider.validationErrors?['images']?[0] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(provider.validationErrors!['images']![0],
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12)),
          )
      ],
    );
  }

  Widget _buildImagePreview(AddProductProvider provider, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(File(provider.pickedImages[index].path),
              width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => provider.removeImage(index),
              child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddImageButton(AddProductProvider provider) {
    return InkWell(
        onTap: () => provider.pickImages(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(8)),
            child: const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Add',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                ]))));
  }
}
