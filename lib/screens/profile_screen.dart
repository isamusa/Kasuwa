import 'package:flutter/material.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/edit_profile_screen.dart';
import 'package:kasuwa/screens/my_orders_screen.dart';
import 'package:kasuwa/screens/shipping_address_screen.dart';
import 'package:kasuwa/screens/shop_profile.dart';
import 'package:kasuwa/screens/wishlist_screen.dart';
import 'package:kasuwa/screens/create_shop_screen.dart';
import 'package:kasuwa/screens/seller_dashboard_screen.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:kasuwa/screens/add_product_screen.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/help_center_screen.dart';
import 'package:kasuwa/screens/security_screen.dart';
import 'package:kasuwa/screens/language_screen.dart';

// Helper for image URLs
String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }
  return '${AppConfig.baseUrl}/storage/$path';
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- NEW: Logout Confirmation Dialog ---
  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out of Kasuwa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await auth.logout(); // Perform logout logic
              if (context.mounted) {
                // Navigate to Login and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Log Out",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Back Gesture Handling: Ensure back button goes to Home
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedHomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            // If user state is lost, force login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            });
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final shop = user['shop'];
          final hasShop = shop != null;

          final avatarUrl = user['profile_picture_url'] != null
              ? storageUrl(user['profile_picture_url'])
              : null;

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: CustomScrollView(
              slivers: [
                // 1. Premium Header
                SliverAppBar(
                  expandedHeight: 220.0,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EnhancedHomeScreen()),
                      (route) => false,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF311B92), AppTheme.primaryColor],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.white,
                                    backgroundImage: avatarUrl != null
                                        ? CachedNetworkImageProvider(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person,
                                            size: 40, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const EditProfileScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Color.fromRGBO(
                                                    0, 0, 0, 0.2),
                                                blurRadius: 4)
                                          ]),
                                      child: const Icon(Icons.edit,
                                          size: 14, color: Colors.black),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user['name'] ?? 'User',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              user['email'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Settings coming soon!")));
                      },
                    ),
                  ],
                ),

                // 2. Content Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Wallet / Loyalty Card
                        _buildWalletCard(context),
                        const SizedBox(height: 24),

                        // Dynamic Seller Section
                        hasShop
                            ? _buildShopManagerWidget(context, shop)
                            : _buildBecomeSellerBanner(context),

                        const SizedBox(height: 24),

                        // My Buying Section
                        _buildSectionHeader("My Buying"),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                  context,
                                  "My Orders",
                                  Icons.local_mall_outlined,
                                  Colors.blue,
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyOrdersScreen()))),
                              _buildDivider(),
                              _buildMenuItem(
                                  context,
                                  "Wishlist",
                                  Icons.favorite_border,
                                  Colors.pink,
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const WishlistScreen()))),
                              _buildDivider(),
                              _buildMenuItem(
                                  context,
                                  "Addresses",
                                  Icons.location_on_outlined,
                                  Colors.orange,
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ShippingAddressScreen()))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Account Preferences
                        _buildSectionHeader("Preferences"),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Column(
                            children: [
                              _buildMenuItem(context, "Security",
                                  Icons.lock_outline, Colors.teal, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SecurityScreen()));
                              }),
                              _buildDivider(),
                              _buildMenuItem(context, "Language",
                                  Icons.language, Colors.indigo, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const LanguageScreen()));
                              }),
                              _buildDivider(),
                              _buildMenuItem(context, "Help Center",
                                  Icons.headset_mic_outlined, Colors.green, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HelpCenterScreen()));
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 1. Updated Logout Logic with Confirmation
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _showLogoutDialog(context, auth),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Color.fromRGBO(255, 0, 0, 0.08),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Log Out",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Text("Kasuwa App v1.0.0",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(height: 55),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widgets ---

  Widget _buildWalletCard(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kasuwa Wallet",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.6),
                        fontSize: 12)),
                const SizedBox(height: 4),
                const Text("₦ 0.00",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Points",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.6),
                        fontSize: 12)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text("0",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopManagerWidget(
      BuildContext context, Map<String, dynamic> shop) {
    final String? shopSlug = shop['slug'];
    final logoUrl =
        shop['logo_url'] != null ? storageUrl(shop['logo_url']) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Color.fromRGBO(128, 128, 128, 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    image: logoUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(logoUrl),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: logoUrl == null
                      ? const Icon(Icons.store, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop['name'] ?? 'My Shop',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text("Active Seller",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SellerDashboardScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Dashboard",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    if (shopSlug != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ShopProfileScreen(shopSlug: shopSlug)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Could not find your shop information.')));
                    }
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text("View Storefront"),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[200]),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    if (shopSlug != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddProductScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Could not find your shop information.')));
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text("Add Item"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBecomeSellerBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CreateShopScreen())),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFEF6C00)]),
        ),
        child: Stack(
          children: [
            Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.storefront,
                    size: 150, color: Color.fromRGBO(255, 255, 255, 0.1))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text("FREE TO JOIN",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                  ),
                  const SizedBox(height: 8),
                  const Text("Become a Seller",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Start selling to millions of customers today.",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.orange),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon,
      Color iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, indent: 70, endIndent: 0, color: Colors.grey[100]);
  }
}
