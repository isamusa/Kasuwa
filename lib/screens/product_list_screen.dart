import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/home_provider.dart'; // Re-using HomeProduct model
import 'package:kasuwa/screens/home_screen.dart'; // Re-using ModernProductCard
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// --- Service to fetch products by category ---
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
        final List<HomeProduct> products =
            (data['data'] as List).map((p) => HomeProduct.fromJson(p)).toList();
        final bool hasMore = data['next_page_url'] != null;
        return {'products': products, 'has_more': hasMore};
      } else {
        throw Exception('Failed to load products for this category');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
}

// --- Provider for this screen's state ---
class ProductListProvider with ChangeNotifier {
  final ProductListService _service = ProductListService();
  final int categoryId;

  List<HomeProduct> _products = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  ProductListProvider({required this.categoryId}) {
    fetchInitialProducts();
  }

  List<HomeProduct> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;

  Future<void> fetchInitialProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result =
          await _service.getProductsByCategory(categoryId: categoryId, page: 1);
      _products = result['products'];
      _hasMore = result['has_more'];
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
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
      print(e);
      _currentPage--; // Revert on error
    }

    _isFetchingMore = false;
    notifyListeners();
  }
}

// --- The UI Screen ---
class ProductListScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const ProductListScreen(
      {super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Use a ChangeNotifierProvider to create a new instance of the provider for this screen
    return ChangeNotifierProvider(
      create: (_) => ProductListProvider(categoryId: categoryId),
      child: Consumer<ProductListProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: Text(categoryName)),
            body: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductListProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingGrid();
    }
    if (provider.products.isEmpty) {
      return Center(child: Text('No products found in this category.'));
    }

    return _ProductGrid(provider: provider);
  }

  Widget _buildLoadingGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}

class _ProductGrid extends StatefulWidget {
  final ProductListProvider provider;
  const _ProductGrid({required this.provider});

  @override
  __ProductGridState createState() => __ProductGridState();
}

class __ProductGridState extends State<_ProductGrid> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        widget.provider.fetchMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: widget.provider.products.length +
          (widget.provider.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.provider.products.length) {
          return Center(child: CircularProgressIndicator());
        }
        final product = widget.provider.products[index];
        return ModernProductCard(product: product);
      },
    );
  }
}
