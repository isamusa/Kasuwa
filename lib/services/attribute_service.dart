import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/models/product_detail_model.dart'; // Re-using the models

class AttributeService {
  /// Fetches a list of all available product attributes and their options.
  Future<List<ProductAttribute>> getAttributes() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/attributes');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((attr) => ProductAttribute.fromJson(attr)).toList();
      } else {
        throw Exception('Failed to load attributes');
      }
    } catch (e) {
      print('AttributeService Error: $e');
      throw Exception(
          'Could not fetch attributes. Please check your connection.');
    }
  }
}
