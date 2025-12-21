import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kasuwa/providers/add_product_provider.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:intl/intl.dart';

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
  State<_AddProductView> createState() => __AddProductViewState();
}

class __AddProductViewState extends State<_AddProductView> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  Future<void> _submit() async {
    final provider = context.read<AddProductProvider>();

    // Validate Form
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill in all required fields', Colors.orange);
      return;
    }

    // Validate Images
    if (provider.pickedImages.isEmpty) {
      _showSnackbar('Please add at least one product image', Colors.orange);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    // Submit
    final success = await provider.submitProduct();
    if (!mounted) return;

    if (success) {
      _showSnackbar('Product published successfully!', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackbar(provider.error ?? 'Upload failed', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddProductProvider>();
    // Calculate safe area for bottom padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text('New Listing',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: provider.isSubmitting ? null : _submit,
            child: const Text("SAVE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Product Media",
                              "Add up to 5 images. First image is the cover."),
                          const SizedBox(height: 12),
                          _buildImagePicker(provider),

                          const SizedBox(height: 24),
                          _buildSectionHeader("Product Details",
                              "Essential information about your item."),
                          const SizedBox(height: 12),
                          _buildBasicInfo(context, provider),

                          const SizedBox(height: 24),
                          _buildSectionHeader("Inventory & Pricing",
                              "Manage stock and selling price."),
                          const SizedBox(height: 12),
                          _buildPricingSection(provider),

                          const SizedBox(height: 24),
                          _buildSectionHeader("Variations",
                              "Does your product have sizes or colors?"),
                          const SizedBox(height: 12),
                          _buildAttributesSection(provider),

                          // Extra padding at bottom of scroll view so content clears the fixed bottom bar
                          SizedBox(height: 100 + bottomPadding),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: _buildBottomBar(provider, context),
    );
  }

  // --- 1. Enhanced Image Picker ---
  Widget _buildImagePicker(AddProductProvider provider) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.pickedImages.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // Add Button
          if (index == 0) {
            return GestureDetector(
              onTap: provider.pickImages,
              child: Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo,
                          color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    const Text("Add Photo",
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))
                  ],
                ),
              ),
            );
          }

          // Image Preview
          final img = provider.pickedImages[index - 1];
          return Stack(
            children: [
              Container(
                width: 110,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                        image: FileImage(File(img.path)), fit: BoxFit.cover),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ]),
              ),
              // Remove Button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => provider.removeImage(index - 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
              // Cover Tag for first image
              if (index == 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                    ),
                    child: const Text("COVER",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  // --- 2. Basic Info Form ---
  Widget _buildBasicInfo(BuildContext context, AddProductProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTextField(
            controller: provider.nameController,
            label: "Product Title",
            hint: "e.g. Nike Air Max 90",
            icon: Icons.tag,
          ),
          const SizedBox(height: 20),

          // Custom Category Picker
          InkWell(
            onTap: () => _showCategoryPicker(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.selectedCategoryId != null
                          ? _getCategoryName(provider)
                          : "Select Category",
                      style: TextStyle(
                          fontSize: 16,
                          color: provider.selectedCategoryId != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontWeight: provider.selectedCategoryId != null
                              ? FontWeight.w500
                              : FontWeight.normal),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildTextField(
            controller: provider.descriptionController,
            label: "Description",
            hint: "Describe your product in detail...",
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // --- 3. Pricing Section ---
  Widget _buildPricingSection(AddProductProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: provider.simplePriceController,
              label: "Price",
              hint: "0.00",
              icon: Icons.attach_money,
              type: TextInputType.number,
              prefixText: "₦ ",
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: provider.simpleStockController,
              label: "Stock",
              hint: "1",
              icon: Icons.inventory_2_outlined,
              type: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Attributes Section ---
  Widget _buildAttributesSection(AddProductProvider provider) {
    if (provider.availableAttributes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(
            child: Text("No variations available for this category",
                style: TextStyle(color: Colors.grey[500]))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: provider.availableAttributes.map((attr) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(attr.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attr.options.map((opt) {
                  final isSelected =
                      provider.selectedOptions[attr.id]?.contains(opt.id) ??
                          false;
                  return GestureDetector(
                    onTap: () => provider.toggleOption(attr.id, opt.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Text(
                        opt.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider()),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Bottom Bar with Safe Area ---
  Widget _buildBottomBar(AddProductProvider provider, BuildContext context) {
    // Add bottom padding for Android gesture bar / iPhone home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Add extra padding at the bottom (bottomPadding) + standard 16
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: provider.isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: provider.isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("PUBLISH PRODUCT",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      color: Colors.white)),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      validator: (v) => v!.isEmpty ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, AddProductProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.category, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text("Select Category",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: provider.categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = provider.categories[i];
                    return ExpansionTile(
                      title: Text(cat.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      leading: CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: const Icon(Icons.folder_open,
                              size: 20, color: Colors.grey)),
                      children: cat.subcategories
                          .map((sub) => ListTile(
                                title: Text(sub.name),
                                contentPadding:
                                    const EdgeInsets.only(left: 72, right: 16),
                                trailing: provider.selectedCategoryId ==
                                        sub.id.toString()
                                    ? const Icon(Icons.check_circle,
                                        color: AppTheme.primaryColor)
                                    : null,
                                onTap: () {
                                  provider.onCategoryChanged(sub.id.toString());
                                  Navigator.pop(context);
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(AddProductProvider provider) {
    if (provider.selectedCategoryId == null) return "";
    for (var cat in provider.categories) {
      for (var sub in cat.subcategories) {
        if (sub.id.toString() == provider.selectedCategoryId) {
          return sub.name;
        }
      }
    }
    return "Selected";
  }
}
