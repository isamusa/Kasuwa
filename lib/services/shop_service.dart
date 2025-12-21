import 'dart:convert';
import 'dart:io';
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

  Future<Map<String, dynamic>> updateShop({
    required String token,
    required String name,
    required String description,
    required String location,
    required String phone,
    File? logo,
    File? banner,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/shop/update');

    // Use MultipartRequest for file uploads
    var request = http.MultipartRequest('POST', uri);

    // Headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['location'] = location; // or address
    request.fields['phone_number'] = phone;
    request.fields['_method'] =
        'PUT'; // Trick for Laravel to handle PUT with files

    // Files
    if (logo != null) {
      request.files.add(await http.MultipartFile.fromPath('logo', logo.path));
    }
    if (banner != null) {
      // FIX: Change field name to 'cover_photo' to match Laravel
      request.files
          .add(await http.MultipartFile.fromPath('cover_photo', banner.path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Shop updated successfully'};
      } else {
        return {'success': false, 'message': 'Failed: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
