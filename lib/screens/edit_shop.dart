import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';

// Helper for image URLs
String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  // 1. If it's a Cloudinary URL (starts with http), return it as is.
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }

  // 2. If it's a legacy local path, build it using the main baseUrl.
  // This removes the need for 'fileBaseUrl' in AppConfig.
  return '${AppConfig.baseUrl}/storage/$path';
}

class EditShopProfileScreen extends StatelessWidget {
  const EditShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ShopProvider(Provider.of<AuthProvider>(context, listen: false)),
      child: const _EditShopView(),
    );
  }
}

class _EditShopView extends StatefulWidget {
  const _EditShopView();
  @override
  State<_EditShopView> createState() => __EditShopViewState();
}

class __EditShopViewState extends State<_EditShopView> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSave(ShopProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await provider.saveChanges();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Shop Updated Successfully"),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Update Failed"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final user = context.read<AuthProvider>().user;
    final shop = user?['shop'] ?? {};

    // Get existing images
    final String? existingBanner = shop['cover_photo_url'];
    final String? existingLogo = shop['logo_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(provider, existingBanner, existingLogo),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionHeader("Shop Details"),
                    const SizedBox(height: 16),
                    _buildFormCard(provider),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => _handleSave(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Save Changes",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      ShopProvider provider, String? existingBanner, String? existingLogo) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration:
            const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
        child: const BackButton(color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Layer
            GestureDetector(
              onTap: provider.pickBanner,
              child: provider.banner != null
                  ? Image.file(provider.banner!, fit: BoxFit.cover)
                  : (existingBanner != null
                      ? CachedNetworkImage(
                          imageUrl: storageUrl(existingBanner),
                          fit: BoxFit.cover)
                      : Container(color: Colors.grey[800])),
            ),
            // Dark Overlay for visibility
            Container(color: Colors.black26),

            // Edit Banner Icon
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: provider.pickBanner,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text("Edit Banner",
                          style: TextStyle(color: Colors.white, fontSize: 12))
                    ],
                  ),
                ),
              ),
            ),

            // Logo Layer (Bottom Left)
            Positioned(
              // Negative to overlapping effect? Sliver restrictions make this hard.
              // Better approach: Positioned at bottom 16
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: provider.pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10)
                          ]),
                      child: ClipOval(
                        child: provider.logo != null
                            ? Image.file(provider.logo!, fit: BoxFit.cover)
                            : (existingLogo != null
                                ? CachedNetworkImage(
                                    imageUrl: storageUrl(existingLogo),
                                    fit: BoxFit.cover)
                                : const Icon(Icons.store,
                                    size: 40, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 12),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildFormCard(ShopProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildTextField("Shop Name", provider.nameController, Icons.store),
          const SizedBox(height: 20),
          _buildTextField(
              "Description", provider.descController, Icons.description,
              maxLines: 3),
          const SizedBox(height: 20),
          _buildTextField("Phone Number", provider.phoneController, Icons.phone,
              type: TextInputType.phone),
          const SizedBox(height: 20),
          _buildTextField("Address / Location", provider.addressController,
              Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      validator: (v) => v!.isEmpty ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
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
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
      ),
    );
  }
}
