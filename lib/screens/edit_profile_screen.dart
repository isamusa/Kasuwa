import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';

String storageUrl(String path) => '${AppConfig.fileBaseUrl}/$path';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;
    _nameController = TextEditingController(text: user['name']);
    _phoneController = TextEditingController(text: user['phone_number']);
    _emailController = TextEditingController(text: user['email']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (selectedImage != null) {
      setState(() {
        _imageFile = File(selectedImage.path);
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final result = await _profileService.updateProfile(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        // THE FIX: Instead of manually updating the user, we tell the AuthProvider
        // to refresh its state from the server, ensuring data consistency.
        await authProvider.refreshUser();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We only need the user here for the initial URL, state changes are handled by the provider
    final user = Provider.of<AuthProvider>(context, listen: false).user!;
    final profilePictureUrl = user['profile_picture_url'] != null
        ? storageUrl(user['profile_picture_url'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(profilePictureUrl),
            const SizedBox(height: 100), // Space for the oversized avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline),
                    SizedBox(height: 16),
                    _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    SizedBox(height: 16),
                    _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        enabled: false),
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
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String? profilePictureUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.vertical(
                bottom:
                    Radius.elliptical(MediaQuery.of(context).size.width, 80.0)),
          ),
        ),
        Positioned(
          top: 70,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (profilePictureUrl != null
                          ? CachedNetworkImageProvider(profilePictureUrl)
                          : null) as ImageProvider?,
                  child: _imageFile == null && profilePictureUrl == null
                      ? Icon(Icons.person, size: 80, color: Colors.grey[400])
                      : null,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool enabled = true,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'This field cannot be empty.'
          : null,
    );
  }
}
