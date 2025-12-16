import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/screens/product_details.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/home_screen.dart';

// THE FIX: The screen is now a simpler StatelessWidget.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The screen now simply consumes the provider's state.
    // The provider itself is reactive and handles fetching data automatically.
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        return PopScope(
          canPop: false,
          // Use onPopInvokedWithResult here as well.
          onPopInvokedWithResult: (bool didPop, _) {
            if (didPop) {
              return;
            }

            // Check if a previous screen exists in the stack.
            if (Navigator.canPop(context)) {
              // If yes, go back.
              Navigator.pop(context);
            } else {
              // If no, go to the home screen.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const EnhancedHomeScreen()),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'My Wishlist (${wishlistProvider.items.length})',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: _buildBody(context, wishlistProvider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WishlistProvider wishlistProvider) {
    if (wishlistProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistProvider.items.isEmpty) {
      return _buildEmptyState();
    }

    return _buildWishlist(context, wishlistProvider);
  }

  Widget _buildWishlist(
      BuildContext context, WishlistProvider wishlistProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: wishlistProvider.items.length,
      itemBuilder: (context, index) {
        final product = wishlistProvider.items[index];
        return _buildWishlistItemCard(context, product, wishlistProvider);
      },
    );
  }

  Widget _buildWishlistItemCard(BuildContext context, HomeProduct product,
      WishlistProvider wishlistProvider) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailsPage(
                    productId: product.id, product: product))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (c, e, s) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter
                              .format(product.salePrice ?? product.price),
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        if (product.salePrice != null)
                          Text(currencyFormatter.format(product.price),
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      wishlistProvider.toggleWishlist(product);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('${product.name} removed from wishlist.'),
                          backgroundColor: Colors.red));
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Remove',
                        style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Add to cart logic can be added here
                      // Provider.of<CartProvider>(context, listen: false).addToCart(product.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Your Wishlist is Empty',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the heart on products to save them for later.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
