// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/config/cache_manager.dart';
import 'package:flutter/services.dart';

import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/screens/cart_screen.dart';
import 'package:kasuwa/screens/profile_screen.dart';
import 'package:kasuwa/screens/browse_screen.dart';
import 'package:kasuwa/screens/notifications_screen.dart';
import 'package:kasuwa/screens/search_screen.dart';
import 'package:kasuwa/screens/wishlist_screen.dart';
import 'package:kasuwa/screens/login_screen.dart';

import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/notification_provider.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';

String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  return '${AppConfig.fileBaseUrl}/$path';
}

void _showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Login Required'),
      content: const Text('You need to be logged in to perform this action.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Login', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
        )
      ],
    ),
  );
}

class StarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(5, (index) {
            IconData icon;
            if (index >= rating) {
              icon = Icons.star_border;
            } else if (index > rating - 0.5 && index < rating) {
              icon = Icons.star_half;
            } else {
              icon = Icons.star;
            }
            return Icon(icon, color: Colors.amber, size: size);
          }),
        ),
        SizedBox(width: 4),
        Text(
          '($reviewCount)',
          style: TextStyle(
            color: AppTheme.textColorSecondary,
            fontSize: size * 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

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
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Pages at index 2, 3, and 4 (Cart, Wishlist, Profile) require login.
    if (index >= 2 && !authProvider.isAuthenticated) {
      _showLoginPrompt(context);
      return;
    }
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 10), curve: Curves.linear);
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: GNav(
            rippleColor: AppTheme.primaryColor.withOpacity(0.1),
            hoverColor: AppTheme.primaryColor.withOpacity(0.05),
            gap: 4,
            activeColor: AppTheme.primaryColor,
            iconSize: 18,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            duration: Duration(milliseconds: 10),
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
                      child: Icon(Icons.shopping_bag_outlined,
                          color: _selectedIndex == 2
                              ? AppTheme.primaryColor
                              : AppTheme.textColorSecondary),
                    );
                  },
                ),
              ),
              GButton(icon: Icons.favorite, text: 'Wishlist'),
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
  final _scrollController = ScrollController();

  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<HomeProvider>(context, listen: false).fetchMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    return PopScope(
      canPop: false,
      // Use the updated onPopInvokedWithResult callback.
      // The 'result' parameter is not needed here, so we can use an underscore.
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }

        final now = DateTime.now();
        final wasBackPressedRecently = _lastPressedAt != null &&
            now.difference(_lastPressedAt!) < const Duration(seconds: 2);

        if (wasBackPressedRecently) {
          // If pressed twice, exit the app.
          SystemNavigator.pop();
        } else {
          // On first press, show a message and record the time.
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildPersonalizedAppBar(authProvider.user),
        body: homeProvider.isLoading && homeProvider.products.isEmpty
            ? _buildLoadingSkeletons()
            : RefreshIndicator(
                onRefresh: () =>
                    Provider.of<HomeProvider>(context, listen: false)
                        .fetchHomeData(forceRefresh: true),
                child: _buildActualContent(homeProvider),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildPersonalizedAppBar(Map<String, dynamic>? user) {
    String userName = user?['name']?.split(' ').first ?? 'Guest';
    String? profileUrl = storageUrl(user?['profile_picture_url']);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hi, $userName 👋",
              style: TextStyle(
                  color: AppTheme.textColorPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text("Let's go shopping!",
              style:
                  TextStyle(color: AppTheme.textColorSecondary, fontSize: 14)),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return Badge(
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              backgroundColor: Colors.red,

              // Add these properties to adjust the position and size
              offset: const Offset(-5, 5), // Moves 5px left and 5px down
              padding: const EdgeInsets.symmetric(
                  horizontal: 5), // Reduces horizontal padding

              child: IconButton(
                icon: Icon(Icons.notifications_none,
                    color: AppTheme.textColorPrimary, size: 22),
                onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NotificationsScreen()))
                    .then((_) => notificationProvider.fetchNotifications()),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
            child: CircleAvatar(
              backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(profileUrl)
                  : null,
              child: (profileUrl == null || profileUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: Colors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActualContent(HomeProvider homeProvider) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: _buildSearchBar(),
          ),
          if (homeProvider.banners.isNotEmpty)
            _buildCarousel(homeProvider.banners),
          _buildSectionHeader("Categories"),
          _buildCategoryList(homeProvider.categories),
          SizedBox(height: 14),
          _buildSectionHeader("New Arrivals"),
          _buildProductGrid(homeProvider),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => SearchScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: AppTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!)),
        child: Row(children: [
          Icon(Icons.search, color: AppTheme.textColorSecondary),
          SizedBox(width: 8),
          Text('Search products...',
              style: TextStyle(color: AppTheme.textColorSecondary))
        ]),
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)))),
            Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                        5,
                        (index) => CircleAvatar(
                            radius: 30, backgroundColor: Colors.white)))),
            SizedBox(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColorPrimary)),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> banners) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
              height: 150,
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
        SizedBox(height: 8),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: banners
                .asMap()
                .entries
                .map((entry) => Container(
                    width: 8.0,
                    height: 8.0,
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
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
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Column(
              children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.cardBackgroundColor,
                    child: Icon(category.icon,
                        size: 20, color: AppTheme.textColorPrimary)),
                SizedBox(height: 4),
                Text(category.name,
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(HomeProvider homeProvider) {
    final productList = homeProvider.products;

    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 190).floor();
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(14.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount < 2 ? 2 : crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: productList.length,
            itemBuilder: (context, index) =>
                ModernProductCard(product: productList[index]),
          );
        }),
        if (homeProvider.isFetchingMore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class ModernProductCard extends StatelessWidget {
  final HomeProduct product;
  const ModernProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFavorite = wishlistProvider.isFavorite(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              productId: product.id,
              product: product,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: CachedNetworkImage(
                      cacheManager: CustomCacheManager.instance,
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white)),
                      errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => wishlistProvider.toggleWishlist(product),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFavorite
                              ? Colors.red
                              : AppTheme.textColorPrimary),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        if (product.reviewsCount > 0)
                          StarRating(
                              rating: product.avgRating,
                              reviewCount: product.reviewsCount,
                              size: 14)
                        else
                          Text("No reviews yet",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormatter
                                    .format(product.salePrice ?? product.price),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor),
                              ),
                              if (product.salePrice != null)
                                Text(
                                  currencyFormatter.format(product.price),
                                  style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.textColorSecondary,
                                      fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
