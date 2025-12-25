import 'package:flutter/material.dart';
import 'package:kasuwa/services/home_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

// --- Data Models ---
class HomeProduct {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? salePrice;
  final double avgRating;
  final int reviewsCount;

  HomeProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.salePrice,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory HomeProduct.fromJson(Map<String, dynamic> json) {
    String extractImage() {
      // 1. Check if we already cached the final URL
      if (json['imageUrl'] != null) return json['imageUrl'];

      // 2. Check API 'images' array
      final images = json['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        // Handle both simple string paths and object structures
        final firstImg = images[0];
        if (firstImg is Map && firstImg['image_url'] != null) {
          return AppConfig.getFullImageUrl(firstImg['image_url']);
        }
      }
      return AppConfig.getFullImageUrl(null); // Placeholder
    }

    return HomeProduct(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      imageUrl: extractImage(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      avgRating: double.tryParse(
              (json['reviews_avg_rating'] ?? json['avgRating']).toString()) ??
          0.0,
      reviewsCount: int.tryParse(
              (json['reviews_count'] ?? json['reviewsCount']).toString()) ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl, // We cache the processed full URL
        'price': price,
        'sale_price': salePrice,
        'avgRating': avgRating,
        'reviewsCount': reviewsCount,
      };
}

class HomeCategory {
  final int id;
  final String name;
  final IconData icon;

  HomeCategory({required this.id, required this.name, required this.icon});

  // Need to handle IconData serialization manually or reconstruction
  factory HomeCategory.fromJson(Map<String, dynamic> json, IconData icon) {
    return HomeCategory(id: json['id'], name: json['name'], icon: icon);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Shop {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;

  Shop(
      {required this.id, required this.name, required this.slug, this.logoUrl});

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      logoUrl: AppConfig.getFullImageUrl(json['logo_url']),
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'slug': slug, 'logo_url': logoUrl};
}

// --- Provider ---
class HomeProvider with ChangeNotifier {
  final HomeService _homeService = HomeService();
  static const String _productCacheKey = 'products_page_';
  static const String _categoryCacheKey = 'homeCategoriesCache';
  static const String _bannerCacheKey = 'homeBannersCache';
  static const String _shopCacheKey = 'homeShopsCache';

  List<HomeProduct> _products = [];
  List<HomeCategory> _categories = [];
  List<dynamic> _banners = [];
  List<Shop> _shops = [];

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  String? _error;

  // Getters
  List<HomeProduct> get products => _products;
  List<HomeCategory> get categories => _categories;
  List<dynamic> get banners => _banners;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;

  HomeProvider() {
    fetchHomeData();
  }

  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && _products.isEmpty) {
      _isLoading = true;
      notifyListeners();
      await _loadDataFromCache(); // Load cache first for speed
      if (_products.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
      }
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (_products.isEmpty) _error = "No internet connection.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final initialData = await _homeService.getInitialData();
      final productData = await _homeService.getProducts(page: 1);

      // Only clear cache if network call succeeded
      await _clearAllCache();

      _categories = initialData['categories'];
      _banners = initialData['banners'];
      _shops = initialData['shops'] ??
          []; // Ensure this key exists in Service if used

      // Reset product list on refresh
      _products = productData['products'];
      _hasMoreProducts = productData['has_more'];
      _currentPage = 2;
      _error = null;

      // Update Cache
      _saveDataToCache(
          _categoryCacheKey, _categories.map((c) => c.toJson()).toList());
      _saveDataToCache(_bannerCacheKey, _banners);
      _saveDataToCache(_shopCacheKey, _shops.map((s) => s.toJson()).toList());
      _saveProductsToCache(1, _products);
    } catch (e) {
      print("Fetch Error: $e");
      if (_products.isEmpty) _error = "Failed to load data.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMoreProducts) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final productData = await _homeService.getProducts(page: _currentPage);
      final List<HomeProduct> newProducts = productData['products'];

      if (newProducts.isNotEmpty) {
        _products.addAll(newProducts);
        _hasMoreProducts = productData['has_more'];
        await _saveProductsToCache(_currentPage, newProducts);
        if (_hasMoreProducts) _currentPage++;
      } else {
        _hasMoreProducts = false;
      }
    } catch (e) {
      // Fail silently for pagination, user can try scrolling again
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  // --- Caching Helpers ---
  Future<void> _loadDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Categories
      final cachedCats = prefs.getString(_categoryCacheKey);
      if (cachedCats != null) {
        final List<dynamic> data = json.decode(cachedCats);
        // Re-map icons manually since we don't store IconData
        final icons = [
          Icons.phone_android,
          Icons.checkroom,
          Icons.kitchen_outlined,
          Icons.chair_outlined,
          Icons.watch_outlined,
          MdiIcons.shoeSneaker,
          MdiIcons.ring
        ];
        _categories = data.asMap().entries.map((e) {
          return HomeCategory.fromJson(e.value, icons[e.key % icons.length]);
        }).toList();
      }

      // Products
      // We load only the first page from cache to start up quickly
      final firstPageJson = prefs.getString('${_productCacheKey}1');
      if (firstPageJson != null) {
        _products = (json.decode(firstPageJson) as List)
            .map((i) => HomeProduct.fromJson(i))
            .toList();
      }

      // Banners
      final cachedBanners = prefs.getString(_bannerCacheKey);
      if (cachedBanners != null) {
        _banners = json.decode(cachedBanners);
      }
    } catch (e) {
      // Corrupt cache? clear it.
      await prefs.clear();
    }
  }

  Future<void> _saveProductsToCache(int page, List<HomeProduct> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((p) => p.toJson()).toList();
    await prefs.setString('$_productCacheKey$page', json.encode(data));
  }

  Future<void> _saveDataToCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  Future<void> _clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Be careful clearing *all* prefs if you store Auth token in prefs.
    // Ideally, only remove keys starting with specific prefix.
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('home') || key.startsWith('products_page')) {
        await prefs.remove(key);
      }
    }
  }
}
