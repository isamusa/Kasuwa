// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, sized_box_for_whitespace
import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import 'package:kasuwa/config/cache_manager.dart';
import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/screens/cart_screen.dart';
import 'package:kasuwa/screens/profile_screen.dart';
import 'package:kasuwa/screens/browse_screen.dart';
import 'package:kasuwa/screens/notifications_screen.dart';
import 'package:kasuwa/screens/product_list_screen.dart';
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

// --- Utility Functions ---
String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${AppConfig.fileBaseUrl}/$path';
}

void _showLoginPrompt(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                size: 32, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('Login Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please sign in to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
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
    this.size = 12, // Smaller default size
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
        const SizedBox(width: 3),
        Text(
          '($reviewCount)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: size * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --- Main Screen Shell ---

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});
  @override
  _EnhancedHomeScreenState createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const BrowseProductsScreen(),
    const CartScreen(),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Make Android System Nav Bar transparent for edge-to-edge look
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (index >= 2 && !authProvider.isAuthenticated) {
      _showLoginPrompt(context);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Slightly cooler grey
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _widgetOptions,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    // Compact Floating Bar
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: GNav(
                rippleColor: AppTheme.primaryColor.withOpacity(0.1),
                hoverColor: AppTheme.primaryColor.withOpacity(0.1),
                gap: 5, // Reduced gap
                activeColor: Colors.white,
                iconSize: 20, // Smaller icons
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                duration: const Duration(milliseconds: 300),
                tabBackgroundColor: AppTheme.primaryColor,
                color: Colors.grey[500],
                textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                tabs: [
                  const GButton(icon: Icons.home_rounded, text: 'Home'),
                  const GButton(icon: Icons.search_rounded, text: 'Browse'),
                  GButton(
                    icon: Icons.shopping_bag_rounded,
                    text: 'Cart',
                    leading: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return Badge(
                          label: Text(cart.itemCount.toString(),
                              style: const TextStyle(fontSize: 10)),
                          isLabelVisible: cart.itemCount > 0,
                          backgroundColor: _selectedIndex == 2
                              ? Colors.white
                              : AppTheme.primaryColor,
                          textColor: _selectedIndex == 2
                              ? AppTheme.primaryColor
                              : Colors.white,
                          smallSize: 8,
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: _selectedIndex == 2
                                ? Colors.white
                                : Colors.grey[500],
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const GButton(icon: Icons.favorite_rounded, text: 'Saved'),
                  const GButton(icon: Icons.person_rounded, text: 'Profile'),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Home Tab Implementation ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  int _currentBanner = 0;
  final _scrollController = ScrollController();
  DateTime? _lastPressedAt;

  // Category Selection State
  int _selectedCategoryIndex = 0; // 0 represents "All" or the first category

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
    _scrollController.addListener(_onScroll);
  }

  void _fetchData({bool force = false}) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.fetchHomeData(forceRefresh: force);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500) {
      Provider.of<HomeProvider>(context, listen: false).fetchMoreProducts();
    }
  }

  Future<void> _handleRefresh() async {
    _fetchData(force: true);
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(context, authProvider),
              _buildStickySearchBar(),
              if (homeProvider.isLoading && homeProvider.products.isEmpty)
                _buildSliverSkeleton()
              else ...[
                if (homeProvider.banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildCarousel(homeProvider.banners),
                  ),

                // Categories Section
                if (homeProvider.categories.isNotEmpty) ...[
                  _buildSliverHeader("Categories", showSeeAll: true),
                  SliverToBoxAdapter(
                    child: _buildCategoryList(homeProvider.categories),
                  ),
                ],

                // Products Section
                _buildSliverHeader("New Arrivals", showSeeAll: true),
                _buildSliverProductGrid(homeProvider),

                if (homeProvider.isFetchingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Extra padding for floating nav
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AuthProvider authProvider) {
    String userName = authProvider.user?['name']?.split(' ').first ?? 'Guest';
    String? profileUrl = storageUrl(authProvider.user?['profile_picture_url']);

    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: const Color(0xFFF4F6F8),
      elevation: 0,
      expandedHeight: 60, // Reduced height
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Hi, $userName 👋",
                        style: const TextStyle(
                            fontSize: 18, // Smaller Title
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const Text("Let's go shopping",
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18, // Smaller Avatar
                      backgroundColor: AppTheme.primaryLight,
                      backgroundImage:
                          (profileUrl != null && profileUrl.isNotEmpty)
                              ? CachedNetworkImageProvider(profileUrl)
                              : null,
                      child: (profileUrl == null || profileUrl.isEmpty)
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickySearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          child: Hero(
            tag: 'searchBar',
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 46, // Sleeker height
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  const Icon(Icons.search,
                      color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  const Text('Search products...',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> banners) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 140, // Reduced height for scaling
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            aspectRatio: 2.0,
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) =>
                setState(() => _currentBanner = index),
          ),
          items: banners.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(item['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8), // Reduced gap
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentBanner == entry.key ? 20.0 : 6.0,
              height: 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppTheme.primaryColor
                    .withOpacity(_currentBanner == entry.key ? 1.0 : 0.2),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSliverHeader(String title, {bool showSeeAll = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), // Tighter padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16, // Scaled down text
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (showSeeAll)
              GestureDetector(
                onTap: () {},
                child: const Text("See All",
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  // --- Functional & Beautiful Categories ---
  Widget _buildCategoryList(List<HomeCategory> categories) {
    return SizedBox(
      height: 90, // Tighter container
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                    categoryId: category.id,
                    categoryName: category.name,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 55, // Smaller circles
                  height: 55,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Icon(category.icon,
                      size: 24, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 11, // Smaller text
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverProductGrid(HomeProvider homeProvider) {
    final productList = homeProvider.products;

    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12), // Tighter side padding
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10, // Reduced vertical gap
          crossAxisSpacing: 10, // Reduced horizontal gap
          childAspectRatio: 0.72, // Taller feel, efficient space usage
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ModernProductCard(product: productList[index]);
          },
          childCount: productList.length,
        ),
      ),
    );
  }

  Widget _buildSliverSkeleton() {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
                height: 140,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 10),
            Row(
                children: List.generate(
                    5,
                    (index) => const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: CircleAvatar(
                            radius: 25, backgroundColor: Colors.white)))),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72),
              itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Enhanced Compact Product Card ---

class ModernProductCard extends StatelessWidget {
  final HomeProduct product;
  const ModernProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14), // Slightly smaller radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 12, // Increased image ratio
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFF9F9F9),
                        child: CachedNetworkImage(
                          cacheManager: CustomCacheManager.instance,
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.3))),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Compact Sale Tag
                  if (product.salePrice != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text("SALE",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  // Compact Fav Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlist, child) {
                        final isFavorite = wishlist.isFavorite(product.id);
                        return GestureDetector(
                          onTap: () => wishlist.toggleWishlist(product),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle),
                            child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color:
                                    isFavorite ? Colors.red : Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.all(10.0), // Tighter padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF333333),
                              height: 1.2),
                        ),
                        const SizedBox(height: 3),
                        if (product.reviewsCount > 0)
                          StarRating(
                              rating: product.avgRating,
                              reviewCount: product.reviewsCount,
                              size: 10)
                        else
                          const Text("No reviews",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormatter
                              .format(product.salePrice ?? product.price),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor),
                        ),
                        if (product.salePrice != null)
                          Text(
                            currencyFormatter.format(product.price),
                            style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 10),
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
