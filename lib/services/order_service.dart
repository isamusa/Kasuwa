import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OrderService {
  static const String _cacheKey = 'ordersCache';

  Future<List<Map<String, dynamic>>> getOrders(
      {required String? token, bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      print("Offline: Loading orders from cache.");
      return _loadFromCache();
    }

    if (token == null) {
      print("Online but not authenticated. Returning empty list.");
      return [];
    }

    if (!forceRefresh) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        _fetchAndCacheOrders(prefs, token);
        return _parseOrders(cachedData);
      }
    }

    return _fetchAndCacheOrders(prefs, token);
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheOrders(
      SharedPreferences prefs, String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/orders');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    });

    if (response.statusCode == 200) {
      await prefs.setString(_cacheKey, response.body);
      return _parseOrders(response.body);
    } else {
      throw Exception('Failed to load orders from network');
    }
  }

  List<Map<String, dynamic>> _parseOrders(String jsonData) {
    final List<dynamic> data = json.decode(jsonData);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      return _parseOrders(cachedData);
    }
    return [];
  }

  Future<bool> createOrder({
    required int shippingAddressId,
    required List<Map<String, dynamic>> items,
    required String? token,
  }) async {
    if (token == null) return false;

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
      return response.statusCode == 201;
    } catch (e) {
      print("Create Order Error: $e");
      return false;
    }
  }
}
