import 'package:flutter/material.dart';
import 'package:kasuwa/services/home_service.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

// --- Data Models (With toJson for caching) ---
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

  // THE FIX: This factory is now unified and more robust.
  factory HomeProduct.fromJson(Map<String, dynamic> json) {
    String getImageUrl(Map<String, dynamic> json) {
      if (json.containsKey('imageUrl')) {
        return json['imageUrl']; // From cache
      }
      final images = json['images'] as List<dynamic>?;
      if (images != null &&
          images.isNotEmpty &&
          images[0]['image_url'] != null) {
        return storageUrl(images[0]['image_url']);
      }
      return 'https://placehold.co/400/purple/white?text=Kasuwa';
    }

    // Safely parse rating and count, checking for both API and cache key names.
    final avgRating = double.tryParse(
            (json['reviews_avg_rating'] ?? json['avgRating'])?.toString() ??
                '0.0') ??
        0.0;

    final reviewsCount = (json['reviews_count'] as int?) ?? 0;

    return HomeProduct(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      imageUrl: getImageUrl(json),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      avgRating: avgRating,
      reviewsCount: reviewsCount,
    );
  }

  // THE FIX: Use consistent keys for caching.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl, // Always cache the full URL
        'price': price,
        'sale_price': salePrice,
        'avgRating': avgRating, // Use the model's property name
        'reviews_count': reviewsCount,
      };
}

class HomeCategory {
  final int id;
  final String name;
  final IconData icon;
  HomeCategory({required this.id, required this.name, required this.icon});

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
      logoUrl: storageUrl(json['logo_url']),
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'slug': slug, 'logo_url': logoUrl};
}

// --- The Provider Class ---
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
    }

    await _loadDataFromCache();

    if (_products.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (_products.isEmpty) {
        _error = "You are offline and have no cached data.";
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final initialData = await _homeService.getInitialData();
      final productData = await _homeService.getProducts(page: 1);

      await _clearAllCache();

      _categories = initialData['categories'];
      _banners = initialData['banners'];
      _shops = initialData['shops'] ?? [];
      _products = productData['products'];
      _hasMoreProducts = productData['has_more'];
      _currentPage = 2;
      _error = null;

      await _saveDataToCache(
          _categoryCacheKey, _categories.map((c) => c.toJson()).toList());
      await _saveDataToCache(_bannerCacheKey, _banners);
      await _saveDataToCache(
          _shopCacheKey, _shops.map((s) => s.toJson()).toList());
      await _saveProductsToCache(1, _products);
    } catch (e) {
      print("Network error during data fetch: $e");
      if (_products.isEmpty) {
        _error = "Could not connect to the server.";
      }
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
      final fetchedProducts = productData['products'];
      _hasMoreProducts = productData['has_more'];

      _products.addAll(fetchedProducts);

      await _saveProductsToCache(_currentPage, fetchedProducts);
      if (_hasMoreProducts) {
        _currentPage++;
      }
      _error = null;
    } catch (e) {
      print("Error fetching more products: $e");
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  // --- Caching Logic ---

  Future<void> _loadDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cachedCategories = prefs.getString(_categoryCacheKey);
      if (cachedCategories != null) {
        final List<dynamic> decodedData = json.decode(cachedCategories);
        final icons = [
          Icons.phone_android,
          Icons.checkroom,
          Icons.kitchen_outlined,
          Icons.chair_outlined,
          Icons.watch_outlined,
          MdiIcons.shoeSneaker,
          MdiIcons.ring
        ];
        _categories = decodedData
            .asMap()
            .entries
            .map((entry) => HomeCategory.fromJson(
                entry.value, icons[entry.key % icons.length]))
            .toList();
      }
      final cachedBanners = prefs.getString(_bannerCacheKey);
      if (cachedBanners != null) _banners = json.decode(cachedBanners);
      final cachedShops = prefs.getString(_shopCacheKey);
      if (cachedShops != null)
        _shops = (json.decode(cachedShops) as List)
            .map((s) => Shop.fromJson(s))
            .toList();

      final keys = prefs.getKeys();
      final productPageKeys =
          keys.where((key) => key.startsWith(_productCacheKey)).toList();
      productPageKeys.sort();

      List<HomeProduct> cachedProducts = [];
      for (var key in productPageKeys) {
        final productsJson = prefs.getString(key);
        if (productsJson != null) {
          cachedProducts.addAll((json.decode(productsJson) as List)
              .map((item) => HomeProduct.fromJson(item))
              .toList());
        }
      }
      if (cachedProducts.isNotEmpty) _products = cachedProducts;

      _currentPage = productPageKeys.length + 1;
    } catch (e) {
      print("Could not load data from cache: $e");
    }
  }

  Future<void> _saveProductsToCache(
      int page, List<HomeProduct> productsToCache) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_productCacheKey$page';
    final List<Map<String, dynamic>> encodableData =
        productsToCache.map((p) => p.toJson()).toList();
    await prefs.setString(cacheKey, json.encode(encodableData));
  }

  Future<void> _saveDataToCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  Future<void> _clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("All cache cleared.");
  }
}
