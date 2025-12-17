import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/checkout_provider.dart'; // For ShippingAddress model
import 'dart:developer';

// Service dedicated to handling checkout-related API calls
class CheckoutService {
  // Fetches the user's saved shipping addresses
  Future<List<ShippingAddress>> getShippingAddresses(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/shipping-addresses');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ShippingAddress.fromJson(json)).toList();
    } else {
      // If the request fails, throw an exception to be caught by the provider
      throw Exception('Failed to load shipping addresses');
    }
  }

  // THE FIX: This method now accepts an orderId and sends it to the backend.
  // It no longer sends the amount.
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
        // THE FIX: The body of the request now correctly sends the order_id.
        body: json.encode({'order_id': orderId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['checkout_url'] != null) {
        // Payment initialization was successful
        return {'success': true, 'url': responseData['checkout_url']};
      } else {
        // The backend returned an error (e.g., validation, order not found)
        return {
          'success': false,
          'message': responseData['message'] ?? 'An unknown error occurred.'
        };
      }
    } catch (e) {
      // A network or connection error occurred
      print(e);
      return {
        'success': false,
        'message': 'Could not connect to the payment service.'
      };
    }
  }

  Future<Map<String, dynamic>> getShippingFee(
      String token, int shippingAddressId, List<int> productIds) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders/calculate-shipping');

    try {
      // Revert to POST
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'shipping_address_id': shippingAddressId,
          'product_ids': productIds,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate shipping fee: ${response.body}');
      }
    } catch (e) {
      print("Get Shipping Fee Error: $e");
      return {
        'shipping_fee': 1500.00,
        'estimated_delivery': '1-3 business days',
      };
    }
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
          'message': responseData['message'] ?? 'An unknown error occurred.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to the payment service.'
      };
    }
  }
}

// A new service class specifically for creating orders
class OrderService {
  // This method now returns the created order's ID on success
  Future<int?> createOrder({
    required int shippingAddressId,
    required List<Map<String, dynamic>> items,
    required String token,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders');
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
          'items': items,
        }),
      );

      if (response.statusCode == 201) {
        // Order created successfully, parse the response to get the new order's ID
        final responseData = json.decode(response.body);
        return responseData['order']['id'];
      } else {
        // Failed to create the order
        print('Failed to create order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }
}
