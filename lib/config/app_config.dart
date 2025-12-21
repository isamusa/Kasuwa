class AppConfig {
  static const String apiBaseUrl =
      'https://kasuwa-backend-yh0v.onrender.com/api';

  static const String baseUrl = 'https://kasuwa-backend-yh0v.onrender.com';
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/150'; // Fallback image
    }

    // 1. If it's already a full Cloudinary URL, return it directly
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return imagePath;
    }

    // 2. If it's a legacy local path (from before the Cloudinary switch)
    // You can keep pointing this to your render storage or a default placeholder
    return 'https://kasuwa-backend-yh0v.onrender.com/storage/$imagePath';
  }
}
