import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kasuwa/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isInitializing = true;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final savedToken = await _authService.getToken();
    if (savedToken == null) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    final cachedUser = await _authService.getUserFromCache();

    _token = savedToken;
    _user = cachedUser;
    _isAuthenticated = true;

    _isInitializing = false;
    notifyListeners();

    await refreshUser(isInitialLoad: true);
  }

  Future<void> refreshUser({bool isInitialLoad = false}) async {
    try {
      final freshUserProfile = await _authService.getUserProfile();

      if (freshUserProfile != null) {
        _user = freshUserProfile;
        _isAuthenticated = true;
      } else {
        if (isInitialLoad) {
          await logout();
        }
      }
    } catch (e) {
      print(
          "Could not refresh user, probably offline. Using cached data. Error: $e");
    }
    notifyListeners();
  }

  // THE FIX: This method now returns the full Map from the service.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _authService.login(email: email, password: password);
      if (result['success']) {
        _token = result['data']['access_token'];
        _user = result['data']['user'];
        _isAuthenticated = true;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'An error occurred.'};
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      return await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } catch (e) {
      return {'success': false, 'message': 'An unknown error occurred.'};
    }
  }

  void updateUserToSeller(Map<String, dynamic> shopData) {
    if (_user != null) {
      _user!['role'] = 'seller';
      notifyListeners();
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final result =
        await _authService.changePassword(currentPassword, newPassword);

    _isLoading = false;
    notifyListeners();

    if (result['success']) {
      return true;
    } else {
      // You can store the error message in a variable if you want to display it in the UI
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<bool> updateProfile(String name, String phone, File? image) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.updateProfile(
        token: _token!,
        name: name,
        phone: phone,
        image: image,
      );

      // Update local user object with the fresh data from server
      if (data['user'] != null) {
        _user = data['user'];
        // Ideally, update SharedPreferences 'userData' here too for persistence
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Update Profile Error: $e");
      return false; // Or throw error to show in UI
    }
  }
}
