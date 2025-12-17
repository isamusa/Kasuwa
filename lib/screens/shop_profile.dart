import 'package:flutter/material.dart';
import 'package:kasuwa/providers/shop_profile_provider.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:share_plus/share_plus.dart';

// --- The Main UI Screen ---
class ShopProfileScreen extends StatelessWidget {
  final String shopSlug;
  const ShopProfileScreen({super.key, required this.shopSlug});

  @override
  Widget build(BuildContext context) {
    // Create a new provider instance scoped to this screen.
    return ChangeNotifierProvider(
      create: (_) => ShopProfileProvider()..fetchShopProfile(shopSlug),
      child: Consumer<ShopProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }
          if (provider.error != null || provider.shopProfile == null) {
            return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text(provider.error ?? 'Shop not found.')));
          }
          return _ShopProfileView(shop: provider.shopProfile!);
        },
      ),
    );
  }

  // A dedicated loading skeleton for a better user experience.
  Widget _buildLoadingState() {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(height: 200, color: Colors.white),
            SizedBox(height: 60),
            Container(height: 20, width: 200, color: Colors.white),
            SizedBox(height: 10),
            Container(height: 15, width: 150, color: Colors.white),
            SizedBox(height: 50), // For TabBar
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The main view, extracted into a StatefulWidget to manage the TabController
class _ShopProfileView extends StatefulWidget {
  final ShopProfile shop;
  const _ShopProfileView({required this.shop});

  @override
  __ShopProfileViewState createState() => __ShopProfileViewState();
}

class __ShopProfileViewState extends State<_ShopProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.surfaceColor,
              elevation: 2,
              flexibleSpace: _buildFlexibleSpaceBar(widget.shop),
              actions: [
                IconButton(
                  icon: Icon(Icons.share_outlined, color: AppTheme.textPrimary),
                  onPressed: () {
                    final url =
                        '${AppConfig.baseUrl}/shops/${widget.shop.slug}';
                    Share.share(
                        'Check out ${widget.shop.name} on Kasuwa: $url');
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Products (${widget.shop.products.length})'),
                  Tab(text: 'About'),
                ],
              ),
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

  Widget _buildFlexibleSpaceBar(ShopProfile shop) {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.pin,
      background: Stack(
        fit: StackFit.expand,
        children: [
          // Cover Photo
          CachedNetworkImage(
            imageUrl: shop.coverPhotoUrl!,
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => Container(color: AppTheme.primaryColor),
          ),
          // Gradient Overlay
          Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7)
              ]))),
          // Shop Info
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0), // Space for TabBar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: shop.logoUrl != null
                        ? CachedNetworkImageProvider(shop.logoUrl!)
                        : null,
                    child: shop.logoUrl == null
                        ? Icon(Icons.storefront, size: 40)
                        : null,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  shop.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(shop.location, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<HomeProduct> products) {
    if (products.isEmpty) {
      return Center(
          child: Text("This shop has no products yet.",
              style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ModernProductCard(product: products[index]);
      },
    );
  }

  Widget _buildAboutTab(ShopProfile shop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About ${shop.name}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(shop.description,
              style: TextStyle(
                  fontSize: 15, height: 1.5, color: Colors.grey[700])),
          Divider(height: 40),
          _buildInfoRow(Icons.location_on_outlined, 'Location', shop.location),
          _buildInfoRow(
              Icons.star_border_outlined, 'Rating', '4.8 (120+ reviews)'),
          _buildInfoRow(
              Icons.policy_outlined, 'Policies', 'View shop policies'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
    );
  }
}
