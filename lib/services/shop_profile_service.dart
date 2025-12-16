import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/shop_profile_provider.dart'; // We will create the models in the provider file

class ShopProfileService {
  Future<ShopProfile> getShopProfile(String slug) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/shops/$slug');
    final response =
        await http.get(url, headers: {'Accept': 'application/json'});
    if (response.statusCode == 200) {
      return ShopProfile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load shop profile');
    }
  }
}
