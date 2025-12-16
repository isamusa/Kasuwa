import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/config/app_config.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  /// Updates the user's profile, including an optional image file.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phoneNumber,
    File? imageFile,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile');
    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Add text fields
    request.fields['name'] = name;
    request.fields['phone_number'] = phoneNumber;
    // Note: Laravel handles POST requests to update by default for multipart forms.
    // If your route is PUT/PATCH, you might need: request.fields['_method'] = 'PUT';

    // Add the image file if one was selected
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture', // This key must match your backend controller
          imageFile.path,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile.'
        };
      }
    } catch (e) {
      print("Error updating profile: $e");
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }
}
