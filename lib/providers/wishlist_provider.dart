import 'package:flutter/material.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:kasuwa/services/wishlist_service.dart';
import 'package:kasuwa/providers/auth_provider.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();
  final AuthProvider _auth;

  List<HomeProduct> _items = [];
  bool _isLoading = false;
  bool _hasFetchedData = false;

  List<HomeProduct> get items => _items;
  bool get isLoading => _isLoading;

  WishlistProvider(this._auth);

  // This method is called by the ProxyProvider whenever AuthProvider changes.
  void update(AuthProvider auth) {
    // If the user is newly authenticated and we haven't fetched the wishlist yet, do it now.
    if (auth.isAuthenticated && !_hasFetchedData) {
      fetchWishlist();
    }
    // If the user logs out, clear the local wishlist data.
    if (!auth.isAuthenticated && _hasFetchedData) {
      _clearWishlist();
    }
  }

  Future<void> fetchWishlist() async {
    _isLoading = true;
    _hasFetchedData = true; // Mark that we've attempted a fetch.
    notifyListeners();

    try {
      final token = _auth.token;
      if (token == null) throw Exception('Not authenticated');
      _items = await _wishlistService.getWishlist(token);
    } catch (e) {
      print("Error fetching wishlist: $e");
      // Don't clear items on a temporary network error, keep the stale data.
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return _items.any((item) => item.id == productId);
  }

  Future<void> toggleWishlist(HomeProduct product) async {
    final token = _auth.token;
    if (token == null) return;

    final bool isCurrentlyFavorite = isFavorite(product.id);

    // Optimistic UI Update for a snappy user experience.
    if (isCurrentlyFavorite) {
      _items.removeWhere((item) => item.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();

    // Send the actual request to the server.
    try {
      if (isCurrentlyFavorite) {
        await _wishlistService.removeFromWishlist(product.id, token);
      } else {
        await _wishlistService.addToWishlist(product.id, token);
      }
    } catch (e) {
      // If the server request fails, revert the UI change.
      print("Error toggling wishlist: $e");
      if (isCurrentlyFavorite) {
        _items.add(product);
      } else {
        _items.removeWhere((item) => item.id == product.id);
      }
      notifyListeners();
    }
  }

  void _clearWishlist() {
    _items = [];
    _hasFetchedData = false;
    notifyListeners();
    print("Wishlist cleared due to logout.");
  }
}
