import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OrderService {
  static const String _cacheKey = 'ordersCache';
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<Map<String, dynamic>>> getOrders(
      {required String? token, bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check internet
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return _loadFromCache();
    }

    if (token == null) return [];

    if (!forceRefresh) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        // Fetch in background to update cache
        _fetchAndCacheOrders(prefs, token);
        return _parseOrders(cachedData);
      }
    }

    return _fetchAndCacheOrders(prefs, token);
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheOrders(
      SharedPreferences prefs, String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      }).timeout(_timeout);

      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        return _parseOrders(response.body);
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      // If network fails, try cache
      return _loadFromCache();
    }
  }

  List<Map<String, dynamic>> _parseOrders(String jsonData) {
    final List<dynamic> data = json.decode(jsonData);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    return cachedData != null ? _parseOrders(cachedData) : [];
  }

  /// Returns the Order ID if successful, or null if failed.
  Future<int?> createOrder({
    required int shippingAddressId,
    required List<Map<String, dynamic>> items,
    required String token,
    double? shippingFee, // Added shippingFee parameter
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders');

    final Map<String, dynamic> body = {
      'shipping_address_id': shippingAddressId,
      'items': items,
    };

    if (shippingFee != null) {
      body['shipping_fee'] = shippingFee;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['order']['id'];
      } else {
        print("Create Order Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create Order Exception: $e");
      return null;
    }
  }
}
