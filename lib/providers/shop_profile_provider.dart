import 'package:flutter/material.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/home_provider.dart'; // Re-using the HomeProduct model
import 'package:kasuwa/services/shop_profile_service.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  // 1. If it's already a full URL (Cloudinary), return it as is.
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }

  // 2. If it's a legacy relative path, prepend the Render base URL.
  return '${AppConfig.baseUrl}/storage/$path';
}

// --- Data Model for a Shop Profile ---
class ShopProfile {
  final int id;
  final String name;
  final String slug;

  final String description;
  final String location;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<HomeProduct> products;

  ShopProfile(
      {required this.id,
      required this.name,
      required this.slug,
      required this.description,
      required this.location,
      this.logoUrl,
      this.coverPhotoUrl,
      required this.products});

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] ?? 'No description available.',
      location: json['location'] ?? 'No location provided.',
      logoUrl: storageUrl(json['logo_url']),
      coverPhotoUrl: json['cover_photo_url'] != null
          ? storageUrl(json['cover_photo_url'])
          : 'https://placehold.co/600x400/6A1B9A/FFFFFF?text=${Uri.encodeComponent(json['name'])}',
      products: (json['products'] as List<dynamic>)
          .map((p) => HomeProduct.fromJson(p))
          .toList(),
    );
  }
}

// --- The Provider Class ---
class ShopProfileProvider with ChangeNotifier {
  final ShopProfileService _service = ShopProfileService();

  ShopProfile? _shopProfile;
  bool _isLoading = false;
  String? _error;

  ShopProfile? get shopProfile => _shopProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchShopProfile(String slug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shopProfile = await _service.getShopProfile(slug);
    } catch (e) {
      _error = e.toString();
      print("ShopProfileProvider Error: $_error");
    }

    _isLoading = false;
    notifyListeners();
  }
}
