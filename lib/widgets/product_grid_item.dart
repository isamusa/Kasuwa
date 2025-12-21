import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/product_details.dart'; // Ensure this import exists

class ProductGridItem extends StatelessWidget {
  final dynamic product;

  const ProductGridItem({super.key, required this.product});

  String storageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // 1. If it's already a full URL (Cloudinary), return it as is.
    if (path.startsWith('http') || path.startsWith('https')) {
      return path;
    }

    // 2. If it's a legacy relative path, prepend the Render base URL.
    return '${AppConfig.baseUrl}/storage/$path';
  }

  // Helper to safely get image URL
  String getImageUrl(dynamic json) {
    if (json == null)
      return 'https://placehold.co/400/purple/white?text=Kasuwa';

    try {
      if (json is Map &&
          json.containsKey('imageUrl') &&
          json['imageUrl'] != null) {
        return json['imageUrl'].toString(); // From cache
      }

      final images = (json is Map) ? (json['images'] as List<dynamic>?) : null;
      if (images != null && images.isNotEmpty) {
        final first = images[0];
        final img = (first is Map && first.containsKey('image_url'))
            ? first['image_url']
            : null;
        if (img != null) return storageUrl(img.toString());
      }
    } catch (_) {
      // fall through to placeholder
    }

    return 'https://placehold.co/400/purple/white?text=Kasuwa';
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final price = double.tryParse(product['price'].toString()) ?? 0.0;
    final name = product['name'] ?? 'Unknown Product';
    final imageUrl = getImageUrl(product);

    return GestureDetector(
      onTap: () {
        // Navigate to details screen
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailsPage(productId: product['id'])));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Product Image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Favorite Icon (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border,
                          size: 16, color: Colors.grey),
                    ),
                  ),
                  // Discount Tag (Top Left) - Optional
                  if (product['discount_price'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "SALE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Product Details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              "4.5", // Placeholder or dynamic rating
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "(20 sold)", // Placeholder or dynamic count
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currency.format(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
