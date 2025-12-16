import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/home_provider.dart'; // For the HomeProduct model

class WishlistService {
  // This service no longer needs an instance of AuthService.

  /// Fetches the user's wishlist from the server.
  Future<List<HomeProduct>> getWishlist(String? token) async {
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('${AppConfig.apiBaseUrl}/wishlist');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => HomeProduct.fromJson(item['product'])).toList();
    } else {
      throw Exception('Failed to load wishlist');
    }
  }

  /// Adds a product to the user's wishlist on the server.
  Future<bool> addToWishlist(int productId, String? token) async {
    if (token == null) return false;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/wishlist/$productId');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Removes a product from the user's wishlist on the server.
  Future<bool> removeFromWishlist(int productId, String? token) async {
    if (token == null) return false;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/wishlist/$productId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    return response.statusCode == 200;
  }
}
