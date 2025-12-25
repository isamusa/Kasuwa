import 'dart:convert';
import 'dart:io';
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

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await getToken(); // Get stored Sanctum token
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation':
              newPassword, // Send confirmation automatically
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
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
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'referral_code': referralCode,
        }),
      );

      final data = jsonDecode(response.body);

      // SUCCESS
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Registration successful'};
      }

      // VALIDATION ERROR (422)
      else if (response.statusCode == 422) {
        String finalError =
            "The email address has already been registerd. Try forgot password instead.";

        // 1. Check if there are detailed 'errors' (Standard Laravel format)
        if (data['errors'] != null && data['errors'] is Map) {
          final errorsMap = data['errors'] as Map<String, dynamic>;

          if (errorsMap.isNotEmpty) {
            // Get the list of errors for the first field that failed (e.g., 'email')
            final firstFieldErrors = errorsMap.values.first;

            // Check if it's a list and has content
            if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
              finalError = firstFieldErrors[
                  0]; // e.g., "The email has already been taken."
            }
          }
        }
        // 2. Fallback: If no 'errors' object, use the top-level message
        else if (data['message'] != null) {
          finalError = data['message'];
        }

        return {'success': false, 'message': finalError};
      }

      // SERVER ERROR
      else {
        return {'success': false, 'message': data['message'] ?? 'Server Error'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please check your internet.'
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String phone,
    File? image,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/user/update');

    var request = http.MultipartRequest(
        'POST', uri); // Using POST with _method=PUT usually safer in Laravel

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['_method'] = 'PUT'; // Method spoofing

    if (image != null) {
      request.files.add(
          await http.MultipartFile.fromPath('profile_picture', image.path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
