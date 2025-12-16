import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/shop.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  Shop? _shop;
  bool _isLoading = false;
  String? _error;
  String? _userType;

  User? get user => _user;
  Shop? get shop => _shop;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userType => _userType;

  UserProvider() {
    _loadUserType();
  }
  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('userType');
    notifyListeners();
  }

  Future<void> login(String email, String password, String loginType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> userData;
      if (loginType == 'shop') {
        userData = await _apiService.shopLogin(email, password);
        _shop = Shop.fromJson(userData['shop']);
      } else {
        userData = await _apiService.customerLogin(email, password);
        _user = User.fromJson(userData['user']);
      }
      _userType = loginType; // Set userType correctly here
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['token']); // Store the token
      await prefs.setString('userType', _userType!);

      if (_userType == 'shop') {
        await fetchShopProfile();
      } else {
        await fetchUserProfile();
      }
    } catch (e) {
      _error = e.toString();
      print('Login Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.logout();
      _user = null;
      _shop = null;
      _userType = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userType');
    } catch (e) {
      _error = e.toString();
      print('Logout Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userType == 'customer' && _user != null) {
        final userData =
            await _apiService.getUserProfile(); // Use instance _apiService
        _user = User.fromJson(userData);
      }
    } catch (e) {
      _error = e.toString();
      print('Profile Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchShopProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userType == 'shop' && _shop != null) {
        print("shop id is: ${_shop!.id}");
        final shopData = await ApiService.getShopProfile(_shop!.id);
        print('Shop Data from API: $shopData');
        _shop = Shop.fromJson(shopData); // Corrected line
        print('Shop Data after parsing: ${_shop!.name}');
      }
    } catch (e) {
      _error = e.toString();
      print('Shop Profile Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateShop(int shopId, Map<String, dynamic> shopData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedShopJson = await _apiService.updateShop(shopId, shopData);
      _shop = Shop.fromJson(updatedShopJson);
    } catch (e) {
      _error = e.toString();
      print('Shop update error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
