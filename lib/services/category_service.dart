import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kasuwa/providers/category_provider.dart'; // THE FIX: Import the models from the provider file

// --- Service to Fetch Data with Caching ---
class CategoryService {
  static const String _cacheKey = 'categoryDataCache';

  Future<List<MainCategory>> getCategories({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) return _parseData(cachedData);
      throw Exception('Offline and no cached data available.');
    }

    if (forceRefresh) {
      return _fetchAndCacheCategories(prefs);
    }

    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      _fetchAndCacheCategories(prefs); // Fetch in background
      return _parseData(cachedData);
    } else {
      return _fetchAndCacheCategories(prefs);
    }
  }

  Future<List<MainCategory>> _fetchAndCacheCategories(
      SharedPreferences prefs) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/categories');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        return _parseData(response.body);
      } else {
        throw Exception('Failed to load categories from server');
      }
    } catch (e) {
      print("CategoryService fetch error: $e");
      throw Exception('Failed to fetch categories from network.');
    }
  }

  List<MainCategory> _parseData(String jsonData) {
    final List<dynamic> data = json.decode(jsonData);

    final icons = [
      Icons.star_outline,
      Icons.tv,
      MdiIcons.tshirtCrewOutline,
      Icons.kitchen_outlined,
      Icons.spa_outlined,
      Icons.sports_basketball_outlined
    ];

    return data.asMap().entries.map((entry) {
      int index = entry.key;
      var categoryData = entry.value;
      return MainCategory.fromJson(categoryData, icons[index % icons.length]);
    }).toList();
  }
}
