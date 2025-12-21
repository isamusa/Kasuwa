import 'package:flutter/material.dart';
import 'package:kasuwa/screens/instructions_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_formKey.currentState!.validate()) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Shop',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildInput("Shop Name", "e.g. Zara Fashion",
                  Icons.store_outlined, _nameController),
              const SizedBox(height: 20),
              _buildInput("Description", "What do you sell?",
                  Icons.description_outlined, _descriptionController,
                  maxLines: 3),
              const SizedBox(height: 20),
              _buildInput("Location", "e.g. Lagos, Nigeria",
                  Icons.location_on_outlined, _locationController),
              const SizedBox(height: 20),
              _buildInput("Business Phone", "For customer inquiries",
                  Icons.phone_outlined, _phoneController,
                  type: TextInputType.phone),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                ),
                child: const Text('Continue',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront,
              size: 40, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text("Start Your Business",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "Enter your shop details to get started. You can change these later.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildInput(String label, String hint, IconData icon,
      TextEditingController controller,
      {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      validator: (v) => v == null || v.isEmpty ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
      ),
    );
  }
}
