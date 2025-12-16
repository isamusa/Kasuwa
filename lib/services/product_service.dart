import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';

class ProductService {
  final AuthService _authService = AuthService();

  /// Fetches product details with an offline-first caching strategy.
  Future<ProductDetail?> getProductDetails(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'product_detail_$productId';
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final url = Uri.parse('${AppConfig.apiBaseUrl}/products/$productId');
        final response =
            await http.get(url, headers: {'Accept': 'application/json'});

        if (response.statusCode == 200) {
          log('RAW JSON RESPONSE: ${response.body}');
          await prefs.setString(cacheKey, response.body);
          return ProductDetail.fromJson(json.decode(response.body));
        }
      } catch (e) {
        log("Network fetch for product details failed: $e");
      }
    }

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      log("Returning product details from cache for product ID: $productId");
      return ProductDetail.fromJson(json.decode(cachedData));
    }
    return null;
  }

  Future<Map<String, dynamic>> getShippingFee(
      String token, int productId, int shippingAddressId) async {
    final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/products/$productId/calculate-shipping');
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
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate shipping fee');
      }
    } catch (e) {
      print("Get Shipping Fee Error: $e");
      // Return a default fee structure on error to prevent crashes
      return {
        'shipping_fee': 1500.00,
        'estimated_delivery': '1-3 business days',
      };
    }
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required String categoryId,
    required List<File> images,
    // These parameters come from the provider
    List<Map<String, dynamic>>? variants,
    String? price,
    String? salePrice,
    String? stockQuantity,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication failed.'};
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/products');
    var request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Add common fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category_id'] = categoryId;

    // --- THIS IS THE MOST IMPORTANT LINE ---
    // It guarantees the 'variants' key is always sent.
    request.fields['variants'] = json.encode(variants ?? []);

    // ONLY add top-level fields for simple products.
    if (variants == null || variants.isEmpty) {
      request.fields['price'] = price ?? '0';
      request.fields['stock_quantity'] = stockQuantity ?? '0';
      if (salePrice != null && salePrice.isNotEmpty) {
        request.fields['sale_price'] = salePrice;
      }
    }
    // Add images
    for (var i = 0; i < images.length; i++) {
      request.files
          .add(await http.MultipartFile.fromPath('images[$i]', images[i].path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Product created successfully.'};
      } else {
        print(response.body);
        return {
          'success': false,
          'message': 'Failed to create product.',
          'errors': json.decode(response.body)
        };
      }
    } catch (e) {
      print("Create Product Exception: $e");
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  /// **Consolidated method** to update an existing product.
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String description,
    required String categoryId,
    String? price,
    String? salePrice,
    String? stockQuantity,
    List<Map<String, dynamic>>? variants,
    List<File>? newImages,
    List<int>? deletedImageIds,
  }) async {
    final token = await _authService.getToken();
    if (token == null)
      return {'success': false, 'message': 'Authentication failed.'};

    final url = Uri.parse('${AppConfig.apiBaseUrl}/products/$productId');
    var request = http.MultipartRequest('POST', url);
    request.fields['_method'] = 'PUT';
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category_id'] = categoryId;

    if (variants != null) {
      request.fields['variants'] = json.encode(variants);
    }
    // Only add simple product fields if there are no variants
    if (variants == null || variants.isEmpty) {
      if (price != null) request.fields['price'] = price;
      if (stockQuantity != null)
        request.fields['stock_quantity'] = stockQuantity;
      if (salePrice != null) request.fields['sale_price'] = salePrice;
    }

    if (newImages != null) {
      for (var i = 0; i < newImages.length; i++) {
        request.files.add(
            await http.MultipartFile.fromPath('images[$i]', newImages[i].path));
      }
    }
    if (deletedImageIds != null && deletedImageIds.isNotEmpty) {
      request.fields['deleted_images'] = json.encode(deletedImageIds);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Product updated successfully.'};
      } else {
        log('Server Update Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to update product.',
          'errors': json.decode(response.body)
        };
      }
    } catch (e) {
      log("Update Product Exception: $e");
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  /// Deletes a product from the server.
  Future<bool> deleteProduct(int productId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/products/$productId');
    try {
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Product Error: $e");
      return false;
    }
  }

  /// Toggles the active/inactive status of a product.
  Future<bool> toggleProductStatus(int productId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final url =
        Uri.parse('${AppConfig.apiBaseUrl}/products/$productId/toggle-status');
    try {
      final response = await http.put(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      return response.statusCode == 200;
    } catch (e) {
      print("Toggle Status Error: $e");
      return false;
    }
  }

  /// Logs a product view for analytics.
  Future<void> logProductView(int productId) async {
    final token = await _authService.getToken();
    if (token == null) return;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/products/$productId/view');
    try {
      await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });
    } catch (e) {
      print("Failed to log product view: $e");
    }
  }
}
