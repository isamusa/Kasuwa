import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/config/app_config.dart';

// --- Service Class for API Communication ---
class ShippingAddressService {
  final AuthService _authService = AuthService();
  Future<bool> createAddress({
    required String name,
    required String recipientName,
    required String recipientPhone,
    required String addressLine1,
    required String city,
    required String state,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/shipping-addresses');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'recipient_name': recipientName,
          'recipient_phone': recipientPhone,
          'address_line_1': addressLine1,
          'city': city,
          'state': state,
        }),
      );
      // 201 means "Created" successfully
      return response.statusCode == 201;
    } catch (e) {
      print(e); // For debugging
      return false;
    }
  }
}

// --- UI for the Add Address Screen ---
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressNameController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedState;
  bool _isLoading = false;

  final ShippingAddressService _addressService = ShippingAddressService();

  final List<String> nigerianStates = [
    'Plateau',
    'Kano',
    /** 'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'FCT - Abuja',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',   
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',    
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
     'Zamfara'
  */
  ];

  @override
  void dispose() {
    _addressNameController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await _addressService.createAddress(
        name: _addressNameController.text,
        recipientName: _recipientNameController.text,
        recipientPhone: _recipientPhoneController.text,
        addressLine1: _addressLine1Controller.text,
        city: _cityController.text,
        state: _selectedState!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Address saved successfully!'),
          backgroundColor: Colors.green,
        ));
        // Pop with a 'true' result to signal the previous screen to refresh
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save address. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Address'),
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
              _buildTextField(
                  controller: _addressNameController,
                  label: 'Address Label',
                  hint: 'e.g., My Home, My Office',
                  icon: Icons.label_outline),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _recipientNameController,
                  label: 'Recipient\'s Full Name',
                  icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _recipientPhoneController,
                  label: 'Recipient\'s Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _addressLine1Controller,
                  label: 'Street Address',
                  hint: 'e.g., No. 1 Ahmadu Bello Way',
                  icon: Icons.home_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _cityController,
                  label: 'City / Town',
                  hint: 'e.g., Jos',
                  icon: Icons.location_city_outlined),
              const SizedBox(height: 16),
              _buildStateDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      IconData? icon,
      String? hint,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7))
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'This field cannot be empty'
          : null,
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'State',
        prefixIcon: Icon(Icons.map_outlined,
            color: AppTheme.primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedState,
      hint: Text('Select your state'),
      isExpanded: true,
      items: nigerianStates.map((String state) {
        return DropdownMenuItem<String>(
          value: state,
          child: Text(state),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedState = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a state' : null,
    );
  }
}
