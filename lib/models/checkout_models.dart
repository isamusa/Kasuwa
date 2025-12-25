class CheckoutCartItem {
  final int productId;
  final String imageUrl;
  final String name;
  final double price;
  final int quantity;
  final String? variantDescription;

  CheckoutCartItem({
    required this.productId,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.quantity,
    this.variantDescription,
  });
}

class ShippingAddress {
  final int id;
  final String recipientName;
  final String fullAddress;
  final String phone;
  final String state;
  final bool isDefault;

  ShippingAddress(
      {required this.id,
      required this.recipientName,
      required this.fullAddress,
      required this.phone,
      required this.state,
      required this.isDefault});

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      recipientName: json['recipient_name'] ?? 'N/A',
      fullAddress:
          '${json['address_line_1']}, ${json['city']}, ${json['state']}',
      phone: json['recipient_phone'] ?? 'N/A',
      state: json['state'] ?? '',
      isDefault: json['is_default'] == 1,
    );
  }
}
