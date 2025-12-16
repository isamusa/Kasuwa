import 'package:flutter/material.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/services/add_review_service.dart';
import 'package:kasuwa/providers/order_details_provider.dart';

// A model to hold the state for a single review being composed
class ReviewInput {
  final int productId;
  final String productName;
  final String imageUrl;
  int rating;
  TextEditingController commentController;

  ReviewInput({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.rating = 5, // Default to a 5-star rating
  }) : commentController = TextEditingController();
}

class AddReviewProvider with ChangeNotifier {
  final AuthProvider _auth;
  final OrderDetail _order;
  final ReviewService _reviewService = ReviewService();

  late List<ReviewInput> reviewInputs;
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  AddReviewProvider(this._auth, this._order) {
    // Initialize the review inputs from the order items
    reviewInputs = _order.items
        .map((item) => ReviewInput(
              productId: item.productId,
              productName: item.productName,
              imageUrl: item.imageUrl,
            ))
        .toList();
  }

  void setRating(int productId, int rating) {
    final index = reviewInputs.indexWhere((r) => r.productId == productId);
    if (index != -1) {
      reviewInputs[index].rating = rating;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitReviews() async {
    final token = _auth.token;
    if (token == null) {
      return {'success': false, 'message': 'You are not logged in.'};
    }

    _isSubmitting = true;
    notifyListeners();

    // Prepare the payload for the API from the user's input
    final reviewsPayload = reviewInputs
        .map((input) => {
              'product_id': input.productId,
              'rating': input.rating,
              'comment': input.commentController.text,
            })
        .toList();

    final result = await _reviewService.submitReviews(
      orderId: _order.id,
      reviews: reviewsPayload,
      token: token,
    );

    _isSubmitting = false;
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    for (var input in reviewInputs) {
      input.commentController.dispose();
    }
    super.dispose();
  }
}
