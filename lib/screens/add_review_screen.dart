import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/add_review_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/order_details_provider.dart'; // Ensure OrderDetail has shop info
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kasuwa/theme/app_theme.dart';

class AddReviewScreen extends StatelessWidget {
  final OrderDetail order;

  const AddReviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AddReviewProvider(
        Provider.of<AuthProvider>(context, listen: false),
        order,
      ),
      child: const _AddReviewScreenContent(),
    );
  }
}

class _AddReviewScreenContent extends StatefulWidget {
  const _AddReviewScreenContent();
  @override
  State<_AddReviewScreenContent> createState() =>
      _AddReviewScreenContentState();
}

class _AddReviewScreenContentState extends State<_AddReviewScreenContent> {
  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final provider = Provider.of<AddReviewProvider>(context, listen: false);

    // Logic inside provider should now loop through _shopRatings and _reviewInputs
    // to send multiple API requests or one big batch request.
    final result = await provider.submitReviews();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result['success']) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddReviewProvider>(context);

    // 1. Group ReviewInputs by Shop ID
    // We assume ReviewInput has a 'shopId' and 'shopName' field.
    // If not, map it from the OrderDetail.items
    final Map<int, List<ReviewInput>> groupedReviews = {};

    for (var input in provider.reviewInputs) {
      if (!groupedReviews.containsKey(input.shopId)) {
        groupedReviews[input.shopId] = [];
      }
      groupedReviews[input.shopId]!.add(input);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Write Reviews'),
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: groupedReviews.length,
            itemBuilder: (context, index) {
              int shopId = groupedReviews.keys.elementAt(index);
              List<ReviewInput> shopProducts = groupedReviews[shopId]!;
              String shopName =
                  shopProducts.first.shopName; // Get name from first item

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SHOP HEADER ---
                  _buildSectionHeader(shopName),

                  // --- RATE THIS SHOP ---
                  _buildShopReviewCard(context, provider, shopId, shopName),
                  const SizedBox(height: 16),

                  // --- RATE PRODUCTS FROM THIS SHOP ---
                  ...shopProducts.map((input) =>
                      _buildProductReviewCard(context, input, provider)),

                  const SizedBox(height: 32), // Spacing between shops
                ],
              );
            },
          ),
          bottomNavigationBar: _buildBottomBar(context, provider),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String shopName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          const Icon(Icons.store, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            ("Sold by $shopName").toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopReviewCard(BuildContext context, AddReviewProvider provider,
      int shopId, String shopName) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF3E5F5), // Light Purple tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 24.0, horizontal: 20.0), // Increased vertical padding
        child: Column(
          children: [
            Text(
              "Rate your experience with $shopName",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),

            // Just the Stars
            RatingBar.builder(
              initialRating: provider.getShopRating(shopId),
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 36, // Slightly larger stars for emphasis
              itemPadding: const EdgeInsets.symmetric(horizontal: 6.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (rating) {
                provider.setShopRating(shopId, rating.toInt());
              },
            ),

            // Optional: Helper text
            const SizedBox(height: 12),
            if (provider.getShopRating(shopId) > 0)
              Text(
                _getRatingLabel(provider.getShopRating(shopId).toInt()),
                style: TextStyle(
                    color: Colors.purple[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }

  // Simple helper to give feedback on star selection
  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return "Poor Service";
      case 2:
        return "Fair Service";
      case 3:
        return "Good Service";
      case 4:
        return "Very Good!";
      case 5:
        return "Excellent!";
      default:
        return "";
    }
  }

  Widget _buildProductReviewCard(BuildContext context, ReviewInput reviewInput,
      AddReviewProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: reviewInput.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[100]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reviewInput.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            RatingBar.builder(
              initialRating: reviewInput.rating.toDouble(),
              minRating: 1,
              itemSize: 28,
              direction: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (rating) {
                provider.setProductRating(
                    reviewInput.productId, rating.toInt());
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewInput.commentController,
              decoration: InputDecoration(
                hintText: 'Review this product...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AddReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16).add(MediaQuery.of(context).viewInsets),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: provider.isSubmitting ? null : () => _submit(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: provider.isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Submit All Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
