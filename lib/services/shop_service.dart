import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/services/auth_service.dart'; // To get the token
import 'package:kasuwa/config/app_config.dart';

class ShopService {
  final AuthService _authService = AuthService(); // Your API URL

  Future<Map<String, dynamic>> createShop({
    required String name,
    required String description,
    required String location,
    required String phoneNumber,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/shops');
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
          'description': description,
          'location': location,
          'phone_number': phoneNumber,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        // 201 = Created
        return {'success': true, 'data': responseBody};
      } else {
        // Handle validation errors or other issues
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create shop.',
          'errors': responseBody['errors']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please check your connection.'
      };
    }
  }

  Future<bool> updateShopProfile(Map<String, String> data) async {
    final token = await _authService.getToken();
    if (token == null) {
      print("Update failed: User not authenticated.");
      return false;
    }

    // We assume the backend has a dedicated endpoint for updating the user's own shop.
    final url = Uri.parse('${AppConfig.apiBaseUrl}/shop/profile');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            "Failed to update shop profile. Status: ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating shop profile: $e");
      return false;
    }
  }
}
