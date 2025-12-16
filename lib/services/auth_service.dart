import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _userCacheKey = 'userProfileCache';

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      print("Error reading token from secure storage: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    try {
      // THE FIX: Use the correct AppConfig.baseUrl
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: data['access_token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userCacheKey, json.encode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'An unknown error occurred.'
        };
      }
    } catch (e) {
      print("Login Service Error: $e");
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'An error occurred.'
        };
      }
    } catch (e) {
      print("Forgot Password Error: $e");
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String otp,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/reset-password');
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'otp': otp,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'An error occurred.'
        };
      }
    } catch (e) {
      print("Reset Password Error: $e");
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        // THE FIX: Use the correct AppConfig.baseUrl
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (e) {
        print("Failed to notify server of logout: $e");
      }
    }
    await _storage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("Auth token deleted and all cached data cleared.");
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      // THE FIX: Use the correct AppConfig.baseUrl
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userCacheKey, json.encode(userData));
        return userData;
      } else if (response.statusCode == 401) {
        return null;
      } else {
        throw Exception(
            'Failed to load user profile with status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Could not fetch user profile: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getUserFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userCacheKey);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    return null;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? referralCode,
  }) async {
    // THE FIX: Use the correct AppConfig.baseUrl
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/register'),
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'referral_code': referralCode,
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['message'],
        'errors': data['errors']
      };
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;

    // THE FIX: Use the correct AppConfig.baseUrl
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    return response.statusCode == 200;
  }
}
