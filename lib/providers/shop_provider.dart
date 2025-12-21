import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/services/shop_service.dart';

class ShopProvider with ChangeNotifier {
  final AuthProvider _auth;
  final ShopService _service = ShopService();
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Image State
  File? _logo;
  File? _banner;

  bool _isLoading = false;

  // Getters
  File? get logo => _logo;
  File? get banner => _banner;
  bool get isLoading => _isLoading;

  ShopProvider(this._auth) {
    _initializeData();
  }

  void _initializeData() {
    final user = _auth.user;
    if (user != null && user['shop'] != null) {
      final shop = user['shop'];
      nameController.text = shop['name'] ?? '';
      descController.text = shop['description'] ?? '';
      phoneController.text = shop['phone_number'] ?? '';
      addressController.text = shop['location'] ?? '';
      // Note: We can't preload files from URLs into File objects easily,
      // so we handle the "show existing vs show new" logic in the UI.
    }
  }

  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _logo = File(image.path);
      notifyListeners();
    }
  }

  Future<void> pickBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _banner = File(image.path);
      notifyListeners();
    }
  }

  Future<bool> saveChanges() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.updateShop(
      token: _auth.token!,
      name: nameController.text,
      description: descController.text,
      location: addressController.text,
      phone: phoneController.text,
      logo: _logo,
      banner: _banner,
    );

    _isLoading = false;
    notifyListeners();

    if (result['success']) {
      // Refresh User Data to reflect new logo/banner in other screens
      await _auth.refreshUser();
      return true;
    }
    return false;
  }
}
