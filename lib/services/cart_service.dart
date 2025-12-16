import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CartService {
  static const String _cacheKey = 'userCartCache';

  Future<List<dynamic>> getCart(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      if (token == null) throw Exception('Not authenticated');
      try {
        return await _fetchAndCacheCart(prefs, token);
      } catch (e) {
        print(
            "Network fetch for cart failed, falling back to cache. Error: $e");
        return _loadFromCache();
      }
    } else {
      print("Offline: Loading cart from cache.");
      return _loadFromCache();
    }
  }

  Future<bool> addVariantToCart(
      {required int variantId,
      required int quantity,
      required String? token}) async {
    if (token == null) return false;
    final url = Uri.parse('${AppConfig.apiBaseUrl}/cart');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'variant_id': variantId, 'quantity': quantity}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> addProductToCart({
    required int productId,
    required int quantity,
    required String? token,
  }) async {
    if (token == null) return false;
    final url = Uri.parse('${AppConfig.apiBaseUrl}/cart');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );
    return response.statusCode == 201;
  }

  Future<List<dynamic>> _fetchAndCacheCart(
      SharedPreferences prefs, String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/cart');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    });

    if (response.statusCode == 200) {
      await prefs.setString(_cacheKey, response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cart from network');
    }
  }

  Future<List<dynamic>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    return cachedData != null ? json.decode(cachedData) : [];
  }

  Future<bool> updateQuantity(
      int cartItemId, int quantity, String? token) async {
    if (token == null) return false;
    final url = Uri.parse('${AppConfig.apiBaseUrl}/cart/$cartItemId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: json.encode({'quantity': quantity}),
    );
    return response.statusCode == 200;
  }

  Future<bool> removeItem(int cartItemId, String? token) async {
    if (token == null) return false;
    final url = Uri.parse('${AppConfig.apiBaseUrl}/cart/$cartItemId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return response.statusCode == 200;
  }
}
