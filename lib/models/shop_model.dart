class Shop {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? logo;
  final int userId;
  final String? coverImage; // Added cover image
  final String? openTime; // Added open time
  final String? closeTime; // Added close time

  Shop({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.logo,
    required this.userId,
    this.coverImage,
    this.openTime,
    this.closeTime,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String?,
      logo: json['logo'] as String?,
      userId: json['user_id'] as int,
      coverImage: json['cover_image'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'phone_number': phoneNumber,
        'logo': logo,
        'user_id': userId,
        'cover_image': coverImage,
        'open_time': openTime,
        'close_time': closeTime,
      };
}
