import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/providers/home_provider.dart'; // Imports HomeProduct model
import 'package:kasuwa/screens/home_screen.dart'; // Imports ModernProductCard

// --- 1. Service: Fetch Products by Category ---
class ProductListService {
  Future<Map<String, dynamic>> getProductsByCategory(
      {required int categoryId, required int page}) async {
    final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/categories/$categoryId/products?page=$page');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle Laravel Pagination Structure
        final List<dynamic> productList = data['data'] ?? [];
        final List<HomeProduct> products =
            productList.map((p) => HomeProduct.fromJson(p)).toList();

        // Check for 'next_page_url' to determine if more pages exist
        final bool hasMore = data['next_page_url'] != null;

        return {'products': products, 'has_more': hasMore};
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// --- 2. Provider: State Management for this Screen ---
class ProductListProvider with ChangeNotifier {
  final ProductListService _service = ProductListService();
  final int categoryId;

  List<HomeProduct> _products = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  ProductListProvider({required this.categoryId}) {
    fetchInitialProducts();
  }

  List<HomeProduct> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInitialProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result =
          await _service.getProductsByCategory(categoryId: categoryId, page: 1);
      _products = result['products'];
      _hasMore = result['has_more'];
    } catch (e) {
      _errorMessage = "Could not load products. Please check your connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    notifyListeners();

    _currentPage++;
    try {
      final result = await _service.getProductsByCategory(
          categoryId: categoryId, page: _currentPage);
      _products.addAll(result['products']);
      _hasMore = result['has_more'];
    } catch (e) {
      _currentPage--; // Revert page on error
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }
}

// --- 3. The UI Screen ---
class ProductListScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const ProductListScreen(
      {super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductListProvider(categoryId: categoryId),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Consumer<ProductListProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchInitialProducts(),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                controller: _ScrollControllerWrapper(provider),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    title: Text(categoryName,
                        style: TextStyle(color: AppTheme.textPrimary)),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    iconTheme: IconThemeData(color: AppTheme.textPrimary),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // TODO: Implement Filter Modal
                        },
                      )
                    ],
                  ),

                  // Error State
                  if (provider.errorMessage != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(provider.errorMessage!),
                            TextButton(
                              onPressed: provider.fetchInitialProducts,
                              child: Text("Retry"),
                            )
                          ],
                        ),
                      ),
                    )
                  // Loading State
                  else if (provider.isLoading)
                    _buildLoadingSliver()
                  // Empty State
                  else if (provider.products.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 60, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text("No products found in this category",
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    )
                  // Product Grid
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ModernProductCard(
                                product: provider.products[index]);
                          },
                          childCount: provider.products.length,
                        ),
                      ),
                    ),

                  // Bottom Loader
                  if (provider.isFetchingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),

                  // Bottom Padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer Effect for Loading
  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  // Helper to create a controller attached to the provider
  ScrollController _ScrollControllerWrapper(ProductListProvider provider) {
    final controller = ScrollController();
    controller.addListener(() {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        provider.fetchMoreProducts();
      }
    });
    return controller;
  }
}
