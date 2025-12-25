import 'package:flutter/foundation.dart';

class AppConfig {
  // live render URL
  static const String baseUrl = 'https://kasuwa-backend-yh0v.onrender.com';
  static const String apiBaseUrl = '$baseUrl/api';

  /// Centralized image URL handler
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://placehold.co/400/purple/white?text=Kasuwa'; // Better placeholder
    }

    // 1. Cloudinary or external URL
    if (path.startsWith('http')) {
      return path;
    }

    // 2. Local storage path (handling active/storage/ prefix if necessary)
    if (path.startsWith('/')) {
      return '$baseUrl/storage$path';
    }

    return '$baseUrl/storage/$path';
  }
}
