import 'package:intl/intl.dart';
import 'package:kasuwa/config/app_config.dart'; // Import AppConfig

String storageUrl(String? path) {
  // FIX: Added '.png' here.
  // Flutter cannot render the default SVG from placehold.co, so we force PNG.
  if (path == null || path.isEmpty) return 'https://placehold.co/100.png';

  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }

  // Clean up the Base URL to ensure we don't duplicate '/api'
  // (Assuming your AppConfig.baseUrl might include /api)
  String baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  // Clean up the path
  String cleanPath = path.startsWith('/') ? path.substring(1) : path;

  return '$baseUrl/storage/$cleanPath';
} // -----------------------

class SellerOrder {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final List<SellerOrderItem> items;

  SellerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] != null
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};

    final address = json['shipping_address'] != null
        ? Map<String, dynamic>.from(json['shipping_address'])
        : <String, dynamic>{};

    final itemsList = json['items'] as List? ?? [];

    return SellerOrder(
      id: json['id'],
      orderNumber: json['order_number'] ?? 'N/A',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      customerName: user['name'] ?? 'Guest',
      customerPhone: user['phone'] ?? address['recipient_phone'] ?? 'N/A',
      shippingAddress: _formatAddress(address),
      items: itemsList
          .map((i) => SellerOrderItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
    );
  }

  static String _formatAddress(Map<String, dynamic> addr) {
    if (addr.isEmpty) return "No address";
    return "${addr['address_line_1'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''}";
  }
}

class SellerOrderItem {
  final int id;
  final String productName;
  final String productCode;
  final String imageUrl;
  final int quantity;
  final double price;
  final String? variant;

  SellerOrderItem({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    this.variant,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] != null
        ? Map<String, dynamic>.from(json['product'])
        : <String, dynamic>{};

    String imgPath = '';

    // Safely extract the image path
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      final firstImg = product['images'][0];
      if (firstImg is Map) {
        imgPath = firstImg['url'] ?? firstImg['image_url'] ?? '';
      } else if (firstImg is String) {
        imgPath = firstImg;
      }
    }

    return SellerOrderItem(
      id: json['id'],
      productName: product['name'] ?? 'Unknown Product',
      productCode: product['sku'] ?? 'N/A',
      // USE THE HELPER HERE
      imageUrl: storageUrl(imgPath),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      variant: json['attributes_summary'],
    );
  }
}
