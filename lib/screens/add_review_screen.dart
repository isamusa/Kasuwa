import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/add_review_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/order_details_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kasuwa/theme/app_theme.dart';

class AddReviewScreen extends StatelessWidget {
  final OrderDetail order;

  const AddReviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Provide the AddReviewProvider to the widget tree
    return ChangeNotifierProvider(
      create: (ctx) => AddReviewProvider(
        Provider.of<AuthProvider>(context, listen: false),
        order,
      ),
      child: const _AddReviewScreenContent(),
    );
  }
}

class _AddReviewScreenContent extends StatelessWidget {
  const _AddReviewScreenContent();

  Future<void> _submit(BuildContext context) async {
    final provider = Provider.of<AddReviewProvider>(context, listen: false);
    final result = await provider.submitReviews();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        Navigator.of(context).pop(); // Go back to the previous screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddReviewProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Reviews'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.reviewInputs.length,
        itemBuilder: (ctx, index) {
          final reviewInput = provider.reviewInputs[index];
          return _buildReviewCard(context, reviewInput);
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : const Text('Submit All Reviews'),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewInput reviewInput) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: reviewInput.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reviewInput.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Your Rating:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: reviewInput.rating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                Provider.of<AddReviewProvider>(context, listen: false)
                    .setRating(reviewInput.productId, rating.toInt());
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewInput.commentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Share your experience...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
