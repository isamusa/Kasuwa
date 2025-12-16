import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/home_provider.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

class AttributeOption {
  final int id;
  final String value;
  final String attributeName;

  AttributeOption(
      {required this.id, required this.value, required this.attributeName});

  factory AttributeOption.fromJson(Map<String, dynamic> json) {
    final attribute = json['attribute'] as Map<String, dynamic>?;
    return AttributeOption(
      id: json['id'],
      value: json['value'],
      attributeName: attribute?['name'] ?? 'Option',
    );
  }
}

class ProductAttribute {
  final int id;
  final String name;
  final List<AttributeOption> options;
  ProductAttribute(
      {required this.id, required this.name, required this.options});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      id: json['id'],
      name: json['name'],
      options: (json['options'] as List<dynamic>)
          .map((opt) => AttributeOption.fromJson(opt))
          .toList(),
    );
  }
}

class ProductVariant {
  final int id;
  final double price;
  final double? salePrice;
  final int stockQuantity;
  final List<AttributeOption> attributeOptions;

  ProductVariant({
    required this.id,
    required this.price,
    this.salePrice,
    required this.stockQuantity,
    required this.attributeOptions,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      stockQuantity: json['stock_quantity'],
      attributeOptions: (json['attribute_options'] as List<dynamic>)
          .map((opt) => AttributeOption.fromJson(opt))
          .toList(),
    );
  }
}

class Review {
  final int id;
  final int rating;
  final String comment;
  final String userName;
  final String? userImageUrl;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    this.userImageUrl,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      userName: user?['name'] ?? 'Anonymous',
      userImageUrl: storageUrl(user?['profile_picture_url']),
      createdAt: json['created_at'],
    );
  }
}

class ProductImage {
  final String url;

  final int? id;
  ProductImage({required this.url, this.id});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(id: json['id'], url: storageUrl(json['image_url']));
  }
}

class ProductShop {
  final int id;
  final String name;
  final String? logoUrl;
  final String slug;

  ProductShop(
      {required this.id, required this.name, this.logoUrl, required this.slug});

  factory ProductShop.fromJson(Map<String, dynamic> json) {
    final shop = json['shops'] as Map<String, dynamic>?;

    return ProductShop(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Seller',
      slug: json['slug'] ?? '',
      logoUrl: storageUrl(shop?['logo_url']),
    );
  }
}

class CategorySnippet {
  final int id;
  final String name;

  CategorySnippet({required this.id, required this.name});

  factory CategorySnippet.fromJson(Map<String, dynamic> json) {
    return CategorySnippet(
      id: json['id'],
      name: json['name'] ?? 'Uncategorized',
    );
  }
}

class ProductDetail {
  final double? price;
  final double? salePrice;
  final int? stockQuantity;
  final int id;
  final String name;
  final String description;
  final List<ProductImage> images;
  final ProductShop shop;
  final String? slug;

  // Review Data
  final double avgRating;
  final int reviewsCount;
  final List<Review> reviews;

  // Variant Data
  final List<ProductAttribute> attributes;
  final List<ProductVariant> variants;
  final List<HomeProduct> relatedProducts;
  final CategorySnippet category;

  ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.shop,
    required this.relatedProducts,
    required this.avgRating,
    required this.reviewsCount,
    required this.reviews,
    required this.attributes,
    required this.variants,
    required this.category,
    this.slug,
    this.price,
    this.salePrice,
    this.stockQuantity,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      slug: json['slug'] ?? '',
      description: json['description'] ?? 'No description available.',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      shop: ProductShop.fromJson(json['shop'] ?? {}),
      relatedProducts: (json['related_products'] as List<dynamic>?)
              ?.map((p) => HomeProduct.fromJson(p))
              .toList() ??
          [],
      avgRating:
          double.tryParse(json['reviews_avg_rating']?.toString() ?? '0.0') ??
              0.0,
      reviewsCount: (json['reviews_count'] as int?) ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromJson(r))
              .toList() ??
          [],
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((attr) => ProductAttribute.fromJson(attr))
              .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          [],
      category: CategorySnippet.fromJson(json['category'] ?? {}),
    );
  }

  factory ProductDetail.fromHomeProduct(HomeProduct homeProduct) {
    return ProductDetail(
      id: homeProduct.id,
      name: homeProduct.name,
      slug: '',
      price: homeProduct.price,
      salePrice: homeProduct.salePrice,
      avgRating: homeProduct.avgRating,
      reviewsCount: homeProduct.reviewsCount,
      images: [ProductImage(url: homeProduct.imageUrl)],
      description: 'Loading description...',
      stockQuantity: 0,
      shop: ProductShop(id: 0, name: 'Loading...', slug: ''),
      relatedProducts: [],
      reviews: [],
      attributes: [],
      variants: [],
      // Provide a default category for the initial state
      category: CategorySnippet(id: 0, name: 'Loading...'),
    );
  }
}
