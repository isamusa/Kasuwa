import 'package:flutter/material.dart';
import 'package:kasuwa/providers/shop_profile_provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/edit_shop.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kasuwa/widgets/product_grid_item.dart';

class ShopProfileScreen extends StatelessWidget {
  final String shopSlug;
  const ShopProfileScreen({super.key, required this.shopSlug});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopProfileProvider()..fetchShopProfile(shopSlug),
      child: Consumer<ShopProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }
          if (provider.error != null || provider.shopProfile == null) {
            return _buildErrorState(context, provider);
          }
          return _ShopProfileView(shop: provider.shopProfile!);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ShopProfileProvider provider) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined,
                  size: 80, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                "Oops! We couldn't load this shop.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? "Please check your internet connection.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => provider.fetchShopProfile(shopSlug),
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: Colors.white),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(height: 20, width: 200, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 15, width: 150, color: Colors.white),
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

class _ShopProfileView extends StatefulWidget {
  final ShopProfile shop;
  const _ShopProfileView({required this.shop});

  @override
  State<_ShopProfileView> createState() => _ShopProfileViewState();
}

class _ShopProfileViewState extends State<_ShopProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        // Show title only when scrolled past cover photo
        bool show = _scrollController.offset > 160;
        if (show != _showTitle) setState(() => _showTitle = show);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final bool isOwner = currentUser != null &&
        currentUser['shop'] != null &&
        currentUser['shop']['id'] == widget.shop.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. Cover Photo AppBar (Pinned)
            SliverAppBar(
              expandedHeight: 200.0,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              title: _showTitle
                  ? Text(widget.shop.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit Shop',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditShopProfileScreen())),
                  ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Share.share(
                        'Check out ${widget.shop.name} on Kasuwa! ${AppConfig.apiBaseUrl}/shop/${widget.shop.slug}');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildCoverPhoto(widget.shop),
              ),
            ),

            // 2. Profile Info & Search (Scrolls with page, NOT pinned)
            SliverToBoxAdapter(
              child: _buildProfileInfoAndSearch(widget.shop),
            ),

            // 3. Tab Bar (Pinned below App Bar)
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Products (${widget.shop.products.length})'),
                    const Tab(text: 'About'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductGrid(widget.shop.products),
            _buildAboutTab(widget.shop),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPhoto(ShopProfile shop) {
    bool hasCover =
        shop.coverPhotoUrl != null && shop.coverPhotoUrl!.isNotEmpty;
    if (hasCover) {
      return CachedNetworkImage(
        imageUrl: shop.coverPhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[300]),
        errorWidget: (context, url, error) => _buildDefaultCoverGradient(),
      );
    }
    return _buildDefaultCoverGradient();
  }

  Widget _buildDefaultCoverGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.store_mall_directory_outlined,
            size: 60, color: Colors.white12),
      ),
    );
  }

  Widget _buildProfileInfoAndSearch(ShopProfile shop) {
    bool hasLogo = shop.logoUrl != null && shop.logoUrl!.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Logo (Overlapping effect visually handled by positioning in list)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: hasLogo
                      ? CachedNetworkImageProvider(shop.logoUrl!)
                      : null,
                  child: !hasLogo
                      ? Icon(Icons.storefront,
                          size: 36, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Name and Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      shop.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.location.isNotEmpty
                                ? shop.location
                                : "Online Store",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat(Icons.star, "4.8", Colors.amber),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.people, "Verified", Colors.blue),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search in ${shop.name}...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6), // Light grey fill
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildProductGrid(List<dynamic> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.grey[50], shape: BoxShape.circle),
                child: Icon(Icons.inventory_2_outlined,
                    size: 50, color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Text("No products listed yet",
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductGridItem(product: products[index].toJson());
      },
    );
  }

  Widget _buildAboutTab(ShopProfile shop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("About Store",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              shop.description.isNotEmpty
                  ? shop.description
                  : "This seller hasn't provided a description yet.",
              style:
                  TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),
            _buildInfoTile(Icons.store, "Shop Name", shop.name),
            _buildInfoTile(Icons.location_on_outlined, "Location",
                shop.location.isNotEmpty ? shop.location : "Not specified"),
            _buildInfoTile(Icons.policy_outlined, "Return Policy",
                "7 Days Return Guarantee"),
            _buildInfoTile(
                Icons.verified_user_outlined, "Joined", "Member since 2024"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- Delegates ---

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
