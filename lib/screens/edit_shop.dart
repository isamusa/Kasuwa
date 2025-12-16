import 'package:flutter/material.dart';
import 'package:kasuwa/services/shop_service.dart'; // We will create this service next
import 'package:kasuwa/providers/auth_provider.dart'; // To get current shop details
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

class EditShopProfileScreen extends StatefulWidget {
  const EditShopProfileScreen({super.key});

  @override
  _EditShopProfileScreenState createState() => _EditShopProfileScreenState();
}

class _EditShopProfileScreenState extends State<EditShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final shop =
        Provider.of<AuthProvider>(context, listen: false).user?['shop'];
    _nameController = TextEditingController(text: shop?['name'] ?? '');
    _descriptionController =
        TextEditingController(text: shop?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _shopService.updateShopProfile({
        'name': _nameController.text,
        'description': _descriptionController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Shop profile updated successfully!'
              : 'Failed to update profile.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
        if (success) {
          // Refresh user data to get the new shop details
          await Provider.of<AuthProvider>(context, listen: false).refreshUser();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Shop Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Placeholder for logo update
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.storefront,
                          size: 50, color: Colors.grey.shade400),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.accentColor,
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 8),
              Center(
                  child: Text("Logo updates coming soon",
                      style: TextStyle(color: Colors.grey))),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a shop name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Shop Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : Text('Save Changes',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
