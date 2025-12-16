import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = '127.0.0.1:8000/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', data['token']);
      return data;
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword,
      String newPassword, String confirmPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  Future<bool> isTokenStored() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token'); // Returns true if token is stored
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Retrieves the token if available
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clears the token
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  Future<dynamic> customerLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customer/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return the decoded user data
    } else {
      throw Exception(
          'Failed to login: ${response.body}'); // Throw an exception with error message
    }
  }

  Future<dynamic> shopLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shop/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return the decoded user data
    } else {
      throw Exception(
          'Failed to login: ${response.body}'); // Throw an exception with error message
    }
  }

  Future<List<dynamic>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/recently-viewed'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch recently viewed');
    }
  }

  Future<void> addToRecentlyViewed(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/recently-viewed'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'product_id': productId.toString()},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add to recently viewed');
    }
  }

  Future<Map<String, dynamic>> registerUser(String name, String email,
      String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      prefs.remove('token'); // Remove token from local storage
      print('Logged out successfully');
    } else {
      throw Exception('Failed to log out: ${response.body}');
    }
  }

  // Fetch all products
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  // Fetch products for a specific shop
  static Future<List<dynamic>> getShopProducts({required int shopId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception(
          'No token found. User is not logged in.'); // Important check
    }

    final response = await http.get(
      Uri.parse('$baseUrl/shops/$shopId/products'),
      headers: {
        'Authorization': 'Bearer $token', // Add the token to the header
      },
    );
    print("response: ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to load products: ${response.body}');
      throw Exception('Failed to load products');
    }
  }

  static Future<Map<String, dynamic>> addProduct(
      Map<String, dynamic> productData, List<File> images,
      {required int shopId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/shops/$shopId/products'));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add product data fields
      productData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add images with correct field names
      for (int i = 0; i < images.length; i++) {
        String fieldName;
        switch (i) {
          case 0:
            fieldName = 'main_image';
            break;
          case 1:
            fieldName = 'extra_image1';
            break;
          case 2:
            fieldName = 'extra_image2';
            break;
          case 3:
            fieldName = 'extra_image3';
            break;
          default:
            continue; // Skip if more than 4 images
        }
        request.files
            .add(await http.MultipartFile.fromPath(fieldName, images[i].path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Failed to add product: ${response.body}');
        throw Exception(
            'Failed to add product: ${response.body}'); // Include response body in exception
      }
    } catch (e) {
      print('Error in addProduct: $e');
      throw Exception('An error occurred while adding the product: $e');
    }
  }

  /// Fetch all categories
  static Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        return jsonDecode(
            response.body); // Adjust key based on your API response
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Fetch subcategories for a specific category
  static Future<List<dynamic>> fetchSubCategories(int categoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories/$categoryId/subcategories'));

      if (response.statusCode == 200) {
        return jsonDecode(
            response.body); // Adjust key based on your API response
      } else {
        throw Exception('Failed to load subcategories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching subcategories: $e');
    }
  }

  static Future<List<dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(
            response.body)['data']; // Assuming API returns data in this format
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
      int productId, Map<String, dynamic> productData,
      {required int shopId, List<File>? images}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Construct the request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/shops/$shopId/products/$productId'),
      );

      // Add Authorization header
      if (token != null) {
        request.headers.addAll({'Authorization': 'Bearer $token'});
      } else {
        throw Exception('No authorization token found');
      }

      // Add product fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Attach images to the request
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          String fieldName;
          switch (i) {
            case 0:
              fieldName = 'main_image';
              break;
            case 1:
              fieldName = 'extra_image1';
              break;
            case 2:
              fieldName = 'extra_image2';
              break;
            case 3:
              fieldName = 'extra_image3';
              break;
            default:
              continue; // Ignore images beyond the allowed number
          }
          request.files.add(
            await http.MultipartFile.fromPath(fieldName, images[i].path),
          );
        }
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Handle the response
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to update product: ${response.body}');
        throw Exception('Failed to update product: ${response.body}');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('An error occurred while updating the product: $e');
    }
  }

  // Delete a product
  static Future<void> deleteProduct(int productId) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/products/$productId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  // Fetch all shops
  static Future<List<dynamic>> getShops() async {
    final response = await http.get(Uri.parse('$baseUrl/shops'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch shops');
    }
  }

  // Fetch a single shop by ID
  static Future<Map<String, dynamic>> getShop(int shopId) async {
    final response = await http.get(Uri.parse('$baseUrl/shops/$shopId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch shop: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getShopProfile(int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found. User is not logged in.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/shops/$shopId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print("shop profile response status code: ${response.statusCode}");
    print("shop profile response: ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load shop profile: ${response.statusCode}');
    }
  }

  // Add a new shop
  static Future<Map<String, dynamic>> addShop(
      Map<String, dynamic> shopData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shops'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(shopData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add shop: ${response.body}');
    }
  }

  // Update a shop
  Future<Map<String, dynamic>> updateShop(
      int shopId, Map<String, dynamic> shopData) async {
    // Removed static
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(shopData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to update shop: ${response.body}');
        throw Exception('Failed to update shop: ${response.body}');
      }
    } catch (e) {
      print('Error updating shop: $e');
      throw Exception('An error occurred while updating the shop: $e');
    }
  }

  // Delete a shop
  static Future<void> deleteShop(int shopId) async {
    final response = await http.delete(Uri.parse('$baseUrl/shops/$shopId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete shop: ${response.body}');
    }
  }
}
