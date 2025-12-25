import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/home_provider.dart'; // For HomeCategory model
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeService {
  // Add a timeout duration
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> getInitialData() async {
    final categoriesUrl = Uri.parse('${AppConfig.apiBaseUrl}/categories');
    try {
      final response = await http.get(categoriesUrl,
          headers: {'Accept': 'application/json'}).timeout(_timeout);

      if (response.statusCode != 200) {
        log('Error fetching categories: ${response.statusCode}');
        throw Exception('Failed to load categories');
      }

      final List<dynamic> categoriesData = json.decode(response.body);

      // Dynamic Icon Mapping (Safeguard against index out of bounds)
      final icons = [
        Icons.phone_android,
        Icons.checkroom,
        Icons.kitchen_outlined,
        Icons.chair_outlined,
        Icons.watch_outlined,
        MdiIcons.shoeSneaker,
        MdiIcons.ring
      ];

      final List<HomeCategory> categories =
          categoriesData.asMap().entries.map((entry) {
        final iconIndex = entry.key % icons.length;
        return HomeCategory(
          id: entry.value['id'],
          name: entry.value['name'],
          icon: icons[iconIndex],
        );
      }).toList();

      final banners = [
        {'image': 'assets/images/banner22.png'},
        {'image': 'assets/images/banner4.jpg'},
        {'image': 'assets/images/banner2.jpg'},
      ];

      return {'categories': categories, 'banners': banners};
    } catch (e) {
      log("HomeService getInitialData error: $e");
      // Return empty data instead of crashing UI
      return {'categories': <HomeCategory>[], 'banners': []};
    }
  }

  Future<Map<String, dynamic>> getProducts({required int page}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/products?page=$page');
    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<HomeProduct> products =
            (data['data'] as List).map((p) => HomeProduct.fromJson(p)).toList();
        final bool hasMore = data['next_page_url'] != null;

        return {'products': products, 'has_more': hasMore};
      } else {
        log("Server Error loading products: ${response.body}");
        throw Exception('Failed to load products');
      }
    } catch (e) {
      log("Error fetching products: $e");
      throw Exception('Failed to fetch products. Please check connection.');
    }
  }
}
