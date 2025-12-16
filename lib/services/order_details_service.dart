import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/order_details_provider.dart';

class OrderDetailsService {
  // This service no longer needs to depend on AuthService.

  Future<OrderDetail> getOrderDetails(int orderId, String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    });

    if (response.statusCode == 200) {
      return OrderDetail.fromJson(json.decode(response.body));
    } else if (response.statusCode == 403) {
      throw Exception('You are not authorized to view this order.');
    } else {
      throw Exception('Failed to load order details.');
    }
  }

  Future<bool> confirmOrderReceived(int orderId, String token) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/confirm-delivery');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });
      // Return true if the API call was successful (status code 200)
      return response.statusCode == 200;
    } catch (e) {
      print('Error confirming order delivery: $e');
      return false;
    }
  }
}
