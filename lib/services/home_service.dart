import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';
import 'dart:developer';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeService {
  /// Fetches the non-paginated data for the home screen (categories, banners).
  Future<Map<String, dynamic>> getInitialData() async {
    final categoriesUrl = Uri.parse('${AppConfig.apiBaseUrl}/categories');
    try {
      final response = await http
          .get(categoriesUrl, headers: {'Accept': 'application/json'});
      if (response.statusCode != 200) {
        throw Exception('Failed to load categories');
      }

      final List<dynamic> categoriesData = json.decode(response.body);
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
        return HomeCategory(
          id: entry.value['id'],
          name: entry.value['name'],
          icon: icons[entry.key % icons.length],
        );
      }).toList();

      final banners = [
        {'image': 'assets/images/banner22.png'},
        {'image': 'assets/images/banner4.jpg'},
        //{'image': 'assets/images/banner55.jpg'},
        //{'image': 'assets/images/banner33.png'},
        {'image': 'assets/images/banner2.jpg'},
        // {'image': 'assets/images/banner44.jpg'},
      ];

      return {'categories': categories, 'banners': banners};
    } catch (e) {
      print("HomeService getInitialData error: $e");
      throw Exception('Failed to fetch initial home screen data.');
    }
  }

  /// Fetches a single page of products from the network.
  Future<Map<String, dynamic>> getProducts({required int page}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/products?page=$page');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<HomeProduct> products =
            (data['data'] as List).map((p) => HomeProduct.fromJson(p)).toList();
        final bool hasMore = data['next_page_url'] != null;

        return {'products': products, 'has_more': hasMore};
      } else {
        throw Exception('Failed to load products page $page');
      }
    } catch (e) {
      log("HomeService getProducts error: $e");
      throw Exception('Failed to fetch products from network.');
    }
  }
}
