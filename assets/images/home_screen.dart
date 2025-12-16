import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/screens/cart_screen.dart';
import 'package:kasuwa/screens/profile_screen.dart';
import 'package:kasuwa/screens/browse_screen.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/screens/notifications_screen.dart';
import 'package:kasuwa/screens/search_screen.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';

// --- AppTheme for consistent styling ---
class AppTheme {
  static const Color primaryColor = Color(0xFF6A1B9A);
  static const Color accentColor = Color(0xFF8E24AA);
  static const Color textColorPrimary = Color(0xFF333333);
  static const Color textColorSecondary = Colors.grey;
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackgroundColor = Colors.white;
}

// --- Data Models ---
class HomeProduct {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? salePrice;
  final double rating;

  HomeProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.salePrice,
    required this.rating,
  });

  factory HomeProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    return HomeProduct(
      id: json['id'],
      name: json['name'],
      imageUrl: images != null && images.isNotEmpty
          ? 'https://optimal-sharp-bat.ngrok-free.app/storage/${images[0]['image_url']}'
          : 'https://placehold.co/400/purple/white?text=Kasuwa',
      price: double.tryParse(json['price'].toString()) ?? 0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
    );
  }
}

class HomeCategory {
  final int id;
  final String name;
  final IconData icon;
  HomeCategory({required this.id, required this.name, required this.icon});
}

// --- NEW: Home Provider for State Management ---
class HomeProvider with ChangeNotifier {
  final HomeService _homeService = HomeService();

  List<HomeProduct> _products = [];
  List<HomeCategory> _categories = [];
  List<dynamic> _banners = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<HomeProduct> get products => _products;
  List<HomeCategory> get categories => _categories;
  List<dynamic> get banners => _banners;
  bool get isLoading => _isLoading;

  // Fetch data only if it hasn't been fetched before, or if forced
  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _homeService.getHomeScreenData();
      _products = data['products'];
      _categories = data['categories'];
      _banners = data['banners'];
      _isInitialized = true;
    } catch (error) {
      print("Error fetching home data: $error");
      // Optionally handle error state
    }

    _isLoading = false;
    notifyListeners();
  }
}

// --- Service to Fetch Home Screen Data ---
class HomeService {
  static const String _baseUrl = 'https://optimal-sharp-bat.ngrok-free.app/api';

  Future<Map<String, dynamic>> getHomeScreenData() async {
    final productsUrl = Uri.parse('$_baseUrl/products');
    final categoriesUrl = Uri.parse('$_baseUrl/categories');
    try {
      final responses =
          await Future.wait([http.get(productsUrl), http.get(categoriesUrl)]);
      if (responses.any((res) => res.statusCode != 200))
        throw Exception('Failed to load data');

      final products = (json.decode(responses[0].body) as List)
          .map((data) => HomeProduct.fromJson(data))
          .toList();
      final categoriesData = json.decode(responses[1].body) as List;

      final icons = [
        Icons.phone_android,
        Icons.checkroom,
        Icons.kitchen_outlined,
        Icons.chair_outlined,
        Icons.watch_outlined
      ];
      final categories = categoriesData.asMap().entries.map((entry) {
        return HomeCategory(
            id: entry.value['id'],
            name: entry.value['name'],
            icon: icons[entry.key % icons.length]);
      }).toList();

      return {
        'products': products,
        'categories': categories,
        'banners': [
          {'image': 'assets/images/banner1.jpg'},
          {'image': 'assets/images/banner2.jpg'}
        ],
      };
    } catch (e) {
      print(e);
      throw Exception('Failed to load home screen data');
    }
  }
}

// --- Main Home Screen Widget with Redesigned Navigation ---
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});
  @override
  _EnhancedHomeScreenState createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    BrowseProductsScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: AppTheme.primaryColor.withOpacity(0.1),
            hoverColor: AppTheme.primaryColor.withOpacity(0.05),
            gap: 8,
            activeColor: AppTheme.primaryColor,
            iconSize: 26,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            duration: Duration(milliseconds: 400),
            tabBackgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            color: AppTheme.textColorSecondary,
            tabs: [
              GButton(icon: Icons.home_outlined, text: 'Home'),
              GButton(icon: Icons.search, text: 'Browse'),
              GButton(
                icon: Icons.shopping_bag_outlined,
                text: 'Cart',
                leading: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return Badge(
                      label: Text(cart.itemCount.toString()),
                      isLabelVisible: cart.itemCount > 0,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: _selectedIndex == 2
                            ? AppTheme.primaryColor
                            : AppTheme.textColorSecondary,
                      ),
                    );
                  },
                ),
              ),
              GButton(icon: Icons.person_outline, text: 'Profile'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    // Use the provider to fetch data, but only if it hasn't been fetched already.
    // listen: false is crucial here to prevent an infinite loop in initState.
    Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
    Provider.of<CartProvider>(context, listen: false).fetchCart();
    Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider for UI updates
    final homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Kasuwa",
            style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none,
                color: AppTheme.textColorPrimary),
            onPressed: () {
              // Make sure to import notifications_screen.dart
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => NotificationsScreen()));
            },
          ),
        ],
      ),
      body: homeProvider.isLoading && homeProvider.products.isEmpty
          ? _buildLoadingSkeletons()
          : RefreshIndicator(
              onRefresh: () => Provider.of<HomeProvider>(context, listen: false)
                  .fetchHomeData(forceRefresh: true),
              child: _buildActualContent(homeProvider),
            ),
    );
  }

  Widget _buildActualContent(HomeProvider homeProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () {
                // Navigate to the new search screen
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SearchScreen()));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textColorSecondary),
                    SizedBox(width: 8),
                    Text('Search products and brands...',
                        style: TextStyle(color: AppTheme.textColorSecondary)),
                  ],
                ),
              ),
            ),
          ),
          if (homeProvider.banners.isNotEmpty)
            _buildCarousel(homeProvider.banners),
          _buildSectionHeader("Categories"),
          _buildCategoryList(homeProvider.categories),
          SizedBox(height: 20),
          _buildSectionHeader("Top Deals"),
          _buildProductGrid(homeProvider.products),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    /* ... Shimmer implementation remains the same ... */
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 50,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                        5,
                        (index) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)))))),
            SizedBox(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65),
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColorPrimary)),
          TextButton(
              onPressed: () {},
              child: Text("See All",
                  style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> banners) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
              height: 180,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) =>
                  setState(() => _currentBanner = index)),
          items: banners
              .map((item) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(item['image'],
                      fit: BoxFit.cover, width: double.infinity)))
              .toList(),
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: banners
                .asMap()
                .entries
                .map((entry) => Container(
                    width: 8.0,
                    height: 8.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(
                            _currentBanner == entry.key ? 0.9 : 0.4))))
                .toList()),
      ],
    );
  }

  Widget _buildCategoryList(List<HomeCategory> categories) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) => CategoryChip(
            icon: categories[index].icon, label: categories[index].name),
      ),
    );
  }

  Widget _buildProductGrid(List<HomeProduct> productList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65),
      itemCount: productList.length,
      itemBuilder: (context, index) =>
          ModernProductCard(product: productList[index]),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const CategoryChip({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
      width: 80,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2))
          ]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 32, color: AppTheme.primaryColor),
        SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: AppTheme.textColorPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center)
      ]));
}

class ModernProductCard extends StatelessWidget {
  final HomeProduct product;
  const ModernProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final discount = product.salePrice != null
        ? ((product.price - product.salePrice!) / product.price * 100).round()
        : 0;
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦');

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ProductDetailsPage(productId: product.id)));
      },
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(product.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: Icon(Icons.error))),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('-$discount%',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(product.rating.toString(),
                        style: TextStyle(color: Colors.grey[700]))
                  ]),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          product.salePrice != null
                              ? currencyFormatter.format(product.salePrice)
                              : currencyFormatter.format(product.price),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                      if (product.salePrice != null)
                        Text(currencyFormatter.format(product.price),
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textColorSecondary,
                                fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
