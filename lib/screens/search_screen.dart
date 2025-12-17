import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kasuwa/providers/home_provider.dart'; // To use the HomeProduct model
import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/config/app_config.dart';

// --- Service for API Communication ---
class SearchService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  Future<List<HomeProduct>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('$_baseUrl/products/search?q=$query');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HomeProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      print(e);
      throw Exception('An error occurred during search.');
    }
  }
}

// --- UI for the Search Screen ---
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchService = SearchService();

  List<HomeProduct> _results = [];
  bool _isLoading = false;
  String _currentQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _currentQuery) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _performSearch(String query) async {
    setState(() {
      _currentQuery = query;
      _isLoading = true;
    });

    try {
      final results = await _searchService.searchProducts(query);
      setState(() {
        _results = results;
      });
    } catch (e) {
      // Optionally show a snackbar or error message
      print(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        title: _buildSearchBar(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search for products...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_searchController.text.isEmpty) {
      return _buildInitialState();
    }
    if (_results.isEmpty) {
      return _buildEmptyState();
    }
    return _buildResultsList();
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('Find Your Favorite Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Search for anything from electronics to fashion.',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('No Results Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
              'We couldn\'t find any products matching "${_searchController.text}".',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return _buildProductResultTile(product);
      },
      separatorBuilder: (context, index) => Divider(),
    );
  }

  Widget _buildProductResultTile(HomeProduct product) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Icon(Icons.image_not_supported),
        ),
      ),
      title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        NumberFormat.currency(locale: 'en_NG', symbol: '₦')
            .format(product.salePrice ?? product.price),
        style: TextStyle(
            color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailsPage(productId: product.id)),
        );
      },
    );
  }
}
