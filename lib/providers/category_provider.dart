import 'package:flutter/material.dart';
import 'package:kasuwa/services/category_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:kasuwa/config/app_config.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

// --- Data Models ---
class SubCategory {
  final int id;
  final String name;
  final String imageUrl;

  SubCategory({required this.id, required this.name, required this.imageUrl});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    String placeholderImage(String label) {
      return 'https://placehold.co/400/purple/white?text=${Uri.encodeComponent(label)}';
    }

    final imagePath = json['image_url'];
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? storageUrl(imagePath)
        : placeholderImage(json['name']);

    return SubCategory(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
    );
  }
}

class MainCategory {
  final int id;
  final String name;
  final IconData icon;
  final List<SubCategory> subcategories;

  MainCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });

  factory MainCategory.fromJson(Map<String, dynamic> json, IconData icon) {
    List<SubCategory> subcategories = [];
    if (json['children'] != null && json['children'] is List) {
      subcategories = (json['children'] as List)
          .map((sub) => SubCategory.fromJson(sub))
          .toList();
    }
    return MainCategory(
      id: json['id'],
      name: json['name'],
      icon: icon,
      subcategories: subcategories,
    );
  }
}

// --- The Provider Class ---
class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<MainCategory> _mainCategories = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<MainCategory> get mainCategories => _mainCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CategoryProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      _mainCategories =
          await _categoryService.getCategories(forceRefresh: forceRefresh);
      _isInitialized = true;
      _error = null;
      print(
          "Categories fetched successfully: ${_mainCategories.length} main categories.");
    } catch (e) {
      _error = e.toString();
      print("Error fetching categories in provider: $_error");
    }

    _isLoading = false;
    notifyListeners();
  }
}
