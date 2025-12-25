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
  final _locationController = TextEditingController(); // Specific address
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedState;

  // List of Nigerian States
  final List<String> _nigerianStates = [
    "Abia",
    "Adamawa",
    "Akwa Ibom",
    "Anambra",
    "Bauchi",
    "Bayelsa",
    "Benue",
    "Borno",
    "Cross River",
    "Delta",
    "Ebonyi",
    "Edo",
    "Ekiti",
    "Enugu",
    "Gombe",
    "Imo",
    "Jigawa",
    "Kaduna",
    "Kano",
    "Katsina",
    "Kebbi",
    "Kogi",
    "Kwara",
    "Lagos",
    "Nasarawa",
    "Niger",
    "Ogun",
    "Ondo",
    "Osun",
    "Oyo",
    "Plateau",
    "Rivers",
    "Sokoto",
    "Taraba",
    "Yobe",
    "Zamfara",
    "FCT"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InstructionsScreen(
            shopData: {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'address': _locationController.text
                  .trim(), // Renamed to address for clarity in backend
              'phone_number': _phoneController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _selectedState ?? '',
              // Concatenate for backward compatibility if backend expects a single 'location' string
              'location':
                  "${_locationController.text.trim()}, ${_cityController.text.trim()}, ${_selectedState ?? ''}",
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edge-to-Edge with keyboard handling
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Shop',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),

                      _buildInput(
                        label: "Shop Name",
                        hint: "e.g. Zara Fashion",
                        icon: Icons.store_outlined,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),

                      _buildInput(
                        label: "Description",
                        hint: "Tell us what you sell...",
                        icon: Icons.description_outlined,
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      _buildInput(
                        label: "Business Phone",
                        hint: "For customer inquiries",
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // State & City Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStateDropdown(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInput(
                              label: "City",
                              hint: "e.g. Ikeja",
                              icon: Icons.location_city_outlined,
                              controller: _cityController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildInput(
                        label: "Street Address",
                        hint: "e.g. 12 Alaba Market Road",
                        icon: Icons.location_on_outlined,
                        controller: _locationController,
                      ),

                      const SizedBox(height: 40), // Spacing for scrolling
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Continue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_rounded,
              size: 40, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text("Create Your Store",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 8),
        const Text(
          "Fill in the details below to launch your online presence.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          validator: (v) =>
              v == null || v.isEmpty ? "$label is required" : null,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Very light grey
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("State",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedState,
          icon:
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          validator: (v) => v == null ? "Required" : null,
          items: _nigerianStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedState = val),
          decoration: InputDecoration(
            hintText: "Select",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon:
                const Icon(Icons.map_outlined, color: Colors.grey, size: 22),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        ),
      ],
    );
  }
}
