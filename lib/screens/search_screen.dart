import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kasuwa/providers/home_provider.dart'; // For HomeProduct
import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/screens/shop_profile.dart'; // You need this screen
import 'package:kasuwa/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/config/app_config.dart';

// --- Models ---
class SearchShop {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;

  SearchShop(
      {required this.id,
      required this.name,
      required this.slug,
      this.logoUrl,
      this.description});

  factory SearchShop.fromJson(Map<String, dynamic> json) {
    return SearchShop(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      logoUrl:
          json['logo_url'], // Ensure backend returns full URL or handle prefix
      description: json['description'],
    );
  }
}

// --- Service ---
class SearchService {
  Future<List<HomeProduct>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse('${AppConfig.apiBaseUrl}/products/search?q=$query');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HomeProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Network error');
    }
  }

  Future<List<SearchShop>> searchShops(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse('${AppConfig.apiBaseUrl}/shops/search?q=$query');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SearchShop.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shops');
      }
    } catch (e) {
      print(e);
      return []; // Return empty on error for now
    }
  }
}

// --- UI ---
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  final _focusNode = FocusNode();
  late TabController _tabController;

  List<HomeProduct> _productResults = [];
  List<SearchShop> _shopResults = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  // Dummy Trending Data
  final List<String> _trending = [
    'Wireless Earbuds',
    'Gaming Laptop',
    'Sneakers',
    'Smart Watch',
    'Phone Case'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    // Auto focus on search field
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _productResults = [];
          _shopResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final products = await _searchService.searchProducts(query);
      final shops = await _searchService.searchShops(query);

      if (!mounted) return;

      setState(() {
        _productResults = products;
        _shopResults = shops;
        _hasSearched = true;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              hintText: "Search products, shops...",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _productResults = [];
                          _shopResults = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Shops"),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildSuggestions();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductResults(),
        _buildShopResults(),
      ],
    );
  }

  // --- 1. Product Results Tab ---
  Widget _buildProductResults() {
    if (_productResults.isEmpty) {
      return _buildEmptyState("No products found", Icons.inventory_2_outlined);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _productResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildProductCard(_productResults[index]),
    );
  }

  Widget _buildProductCard(HomeProduct product) {
    // Helper to format image URL correctly
    String getImageUrl(String? path) {
      if (path == null || path.isEmpty) return 'https://placehold.co/100';
      if (path.startsWith('http')) return path;
      return '${AppConfig.baseUrl}/storage/$path'; // Use AppConfig.baseUrl
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                        productId: product.id, product: product)));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: getImageUrl(product.imageUrl),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Colors.grey[100]),
                    errorWidget: (c, u, e) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            NumberFormat.currency(
                                    locale: 'en_NG',
                                    symbol: '₦',
                                    decimalDigits: 0)
                                .format(product.salePrice ?? product.price),
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          if (product.salePrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              NumberFormat.currency(
                                      locale: 'en_NG',
                                      symbol: '₦',
                                      decimalDigits: 0)
                                  .format(product.price),
                              style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                  fontSize: 12),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (product.avgRating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              product.avgRating.toStringAsFixed(1),
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              " (${product.reviewsCount})",
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Shop Results Tab ---
  Widget _buildShopResults() {
    if (_shopResults.isEmpty) {
      return _buildEmptyState("No shops found", Icons.storefront_outlined);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _shopResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildShopCard(_shopResults[index]),
    );
  }

  Widget _buildShopCard(SearchShop shop) {
    String getLogoUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return '${AppConfig.baseUrl}/storage/$path';
    }

    final logoUrl = getLogoUrl(shop.logoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShopProfileScreen(shopSlug: shop.slug)));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: logoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(logoUrl)
                      : null,
                  child: logoUrl.isEmpty
                      ? const Icon(Icons.store, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (shop.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          shop.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("Visit",
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Common Widgets ---

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Trending Searches",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trending
                .map((term) => ActionChip(
                      label: Text(term),
                      backgroundColor: Colors.white,
                      elevation: 1,
                      labelStyle: const TextStyle(color: Colors.black87),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200)),
                      onPressed: () {
                        _searchController.text = term;
                        _performSearch(term);
                      },
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Try different keywords",
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
