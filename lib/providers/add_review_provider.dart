import 'package:flutter/material.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/services/add_review_service.dart';
import 'package:kasuwa/providers/order_details_provider.dart';

// A model to hold the state for a single review being composed
class ReviewInput {
  final int productId;
  final String productName;
  final String imageUrl;
  final int shopId;
  final String shopName;
  int rating;
  TextEditingController commentController;

  ReviewInput({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.shopId = 0,
    this.shopName = '',
    this.rating = 5, // Default to a 5-star rating
  }) : commentController = TextEditingController();
}

class AddReviewProvider with ChangeNotifier {
  final AuthProvider _auth;
  final OrderDetail _order;
  final ReviewService _reviewService = ReviewService();

  late List<ReviewInput> reviewInputs;
  bool _isSubmitting = false;

  // Shop Rating State
  final Map<int, int> _shopRatings = {}; // {shopId: rating}

  bool get isSubmitting => _isSubmitting;

  AddReviewProvider(this._auth, this._order) {
    _initializeData();
  }

  void _initializeData() {
    // 1. Initialize Product Inputs
    reviewInputs = _order.items
        .map((item) => ReviewInput(
              productId: item.productId,
              productName: item.productName,
              imageUrl: item
                  .imageUrl, // Ensure this matches your OrderDetailItem field name
              shopId: item.shopId, // Passing the shopId from the item
              shopName: item.shopName, // Passing the shopName from the item
            ))
        .toList();

    // 2. Initialize Shop Inputs (Unique shops only)
  }

  // --- Getters ---
  double getShopRating(int shopId) => _shopRatings[shopId]?.toDouble() ?? 0.0;

  void setShopRating(int shopId, int rating) {
    _shopRatings[shopId] = rating;
    notifyListeners();
  }

  void setProductRating(int productId, int rating) {
    final index = reviewInputs.indexWhere((r) => r.productId == productId);
    if (index != -1) {
      reviewInputs[index].rating = rating;
      notifyListeners();
    }
  }

  // --- Submission ---
  Future<Map<String, dynamic>> submitReviews() async {
    final token = _auth.token;
    if (token == null) {
      return {'success': false, 'message': 'You are not logged in.'};
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // 1. Product Reviews (Unchanged)
      final productReviews = reviewInputs
          .map((input) => {
                'product_id': input.productId,
                'rating': input.rating,
                'comment': input.commentController.text,
              })
          .toList();

      // 2. Shop Reviews (RATING ONLY)
      final shopReviews = _shopRatings.entries
          .map((entry) {
            return {
              'shop_id': entry.key,
              'rating': entry.value,
              // No comment sent for shops
            };
          })
          .where((r) => (r['rating'] as int) > 0)
          .toList();

      final result = await _reviewService.submitReviews(
        orderId: _order.id,
        reviews: productReviews,
        shopReviews: shopReviews,
        token: token,
      );

      _isSubmitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  @override
  void dispose() {
    // Dispose product controllers
    for (var input in reviewInputs) {
      input.commentController.dispose();
    }
    // Dispose shop controllers

    super.dispose();
  }
}
