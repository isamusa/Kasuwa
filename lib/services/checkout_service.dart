import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/models/checkout_models.dart';

class CheckoutService {
  Future<List<ShippingAddress>> getShippingAddresses(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/shipping-addresses');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ShippingAddress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load shipping addresses');
    }
  }

  Future<Map<String, dynamic>> initializePayment({
    required int orderId,
    required String token,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/payment/initialize');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'order_id': orderId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['checkout_url'] != null) {
        return {'success': true, 'url': responseData['checkout_url']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Payment initialization failed.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error during payment.'};
    }
  }

  Future<Map<String, dynamic>> getShippingFee(
      String token, int shippingAddressId, List<CheckoutCartItem> items) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders/calculate-shipping');

    final itemsPayload = items
        .map((item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
            })
        .toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'shipping_address_id': shippingAddressId,
          'items': itemsPayload,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Shipping Calc Error: $e");
    }
    return {
      'shipping_fee': 1500.00,
      'estimated_delivery': '3-5 business days',
    };
  }

  Future<Map<String, dynamic>> retryOrderPayment({
    required int orderId,
    required String token,
  }) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/retry-payment');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['checkout_url'] != null) {
        return {'success': true, 'url': responseData['checkout_url']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Retry failed.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error.'};
    }
  }
}
