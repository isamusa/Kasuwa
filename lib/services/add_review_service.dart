import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';

class ReviewService {
  Future<Map<String, dynamic>> submitReviews({
    required int orderId,
    required List<Map<String, dynamic>> reviews,
    required String token,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/reviews/order');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order_id': orderId,
          'reviews': reviews,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit reviews.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }
}
