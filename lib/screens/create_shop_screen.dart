import 'package:flutter/material.dart';
import 'package:kasuwa/screens/instructions_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  _CreateShopScreenState createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController =
      TextEditingController(); // NEW: Phone number controller

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose(); // NEW: Dispose the new controller
    super.dispose();
  }

  void _proceedToInstructions() {
    if (_formKey.currentState!.validate()) {
      // UPDATED: Instead of calling the API, navigate to the next screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InstructionsScreen(
            shopData: {
              'name': _nameController.text,
              'description': _descriptionController.text,
              'location': _locationController.text,
              'phone_number': _phoneController.text,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Shop (Step 1 of 2)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTextField(
                  controller: _nameController,
                  label: 'Shop Name',
                  hint: 'e.g., Bello\'s Gadget Haven',
                  icon: Icons.storefront_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Shop Description',
                  hint: 'What makes your shop special?',
                  icon: Icons.description_outlined,
                  maxLines: 4),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g., Terminus Market, Jos',
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                // NEW: Phone number field
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g., 08012345678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _proceedToInstructions, // UPDATED: Button action
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Proceed to Instructions',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.add_business_outlined,
            size: 60, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text('Tell Us About Your Shop',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
            'This information will be visible to customers on your shop profile.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'The $label cannot be empty.'
          : null,
    );
  }
}
