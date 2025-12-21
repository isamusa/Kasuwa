import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/home_screen.dart'; // Reuse ModernProductCard

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('My Wishlist',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
          ),
          body: _buildBody(context, wishlistProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WishlistProvider wishlistProvider) {
    if (wishlistProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Your wishlist is empty",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ],
        ),
      );
    }

    // Reuse the Product Grid logic but mapping from Wishlist items
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: wishlistProvider.items.length,
      itemBuilder: (context, index) {
        final product = wishlistProvider.items[index];
        // We reuse ModernProductCard from home_screen.dart for consistency
        return Stack(
          children: [
            ModernProductCard(product: product),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => wishlistProvider.toggleWishlist(product),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ]),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
