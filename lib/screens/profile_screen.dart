import 'package:flutter/material.dart';
import 'package:kasuwa/screens/contact_admin_screen.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:kasuwa/screens/shop_profile.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/create_shop_screen.dart';
import 'package:kasuwa/screens/edit_profile_screen.dart';
import 'package:kasuwa/screens/add_product_screen.dart';
import 'package:kasuwa/screens/shipping_address_screen.dart';
import 'package:kasuwa/screens/my_orders_screen.dart';
import 'package:kasuwa/screens/seller_dashboard_screen.dart';
import 'package:kasuwa/screens/wishlist_screen.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/notifications_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    return PopScope(
      canPop: false,
      // Use onPopInvokedWithResult here as well.
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }

        // Check if a previous screen exists in the stack.
        if (Navigator.canPop(context)) {
          // If yes, go back.
          Navigator.pop(context);
        } else {
          // If no, go to the home screen.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('My Profile',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 1,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(
                context,
                name: user?['name'] ?? 'No Name',
                email: user?['email'] ?? 'No Email',
                profilePictureUrl: user?['profile_picture_url'],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('My Account'),
              _buildSettingsCard(
                context,
                [
                  _buildListTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MyOrdersScreen()));
                      }),
                  _buildListTile(
                      icon: Icons.favorite_border,
                      title: 'My Wishlist',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WishlistScreen()));
                      }),
                  _buildListTile(
                      icon: Icons.location_on_outlined,
                      title: 'Shipping Addresses',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ShippingAddressScreen()));
                      }),
                ],
              ),
              const SizedBox(height: 24),

              if (user?['role'] == 'seller')
                _buildSellerSection(
                    context) // Show dashboard if they are a seller
              else
                _buildBecomeSellerCard(
                    context), // Show CTA if they are a regular user

              const SizedBox(height: 24),

              _buildSectionTitle('Settings'),
              _buildSettingsCard(
                context,
                [
                  _buildListTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NotificationsScreen()));
                      }),
                  _buildListTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ContactAdminScreen()));
                      }),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Referrals'),
                  _buildReferralCard(context, user?['referral_code']),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: OutlinedButton(
                  onPressed: () => {
                    Provider.of<AuthProvider>(context, listen: false).logout(),
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => LoginScreen()))
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    side: BorderSide(color: Colors.red.shade700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Logout',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                  child: Text('Version 1.0.0',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  String storageUrl(String path) => '${AppConfig.fileBaseUrl}/$path';
  Widget _buildProfileHeader(BuildContext context,
      {required String name,
      required String email,
      String? profilePictureUrl}) {
    // Construct the full URL for the network image
    final fullImageUrl = profilePictureUrl != null
        ? '${AppConfig.fileBaseUrl.replaceAll("/api", "")}/storage/$profilePictureUrl'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: fullImageUrl != null
                ? CachedNetworkImageProvider(fullImageUrl)
                : null,
            backgroundColor: AppTheme.backgroundColor,
            child: fullImageUrl == null
                ? Icon(Icons.person, size: 35, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(email,
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          IconButton(
              icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen()));
              }),
        ],
      ),
    );
  }

  // Widget for sellers now correctly navigates to the shop profile
  Widget _buildSellerSection(BuildContext context) {
    // Get the shop slug from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shop = authProvider.user?['shop'];
    final String? shopSlug = shop?['slug'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('My Shop'),
        _buildSettingsCard(
          context,
          [
            _buildListTile(
                icon: Icons.add_business_outlined,
                title: 'Add New Product',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddProductScreen()));
                }),
            _buildListTile(
                icon: Icons.storefront_outlined,
                title: 'Visit My Shop',
                onTap: () {
                  // Check if the slug exists and pass it to the ShopProfileScreen
                  if (shopSlug != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ShopProfileScreen(shopSlug: shopSlug)));
                  } else {
                    // Handle case where slug is missing, though this shouldn't happen for a seller.
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Could not find your shop information.')));
                  }
                }),
            _buildListTile(
                icon: Icons.dashboard_outlined,
                title: 'Seller Dashboard',
                subtitle: 'Manage products and view earnings',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SellerDashboardScreen()));
                }),
          ],
        ),
      ],
    );
  }

  // NEW: Widget for regular users
  Widget _buildBecomeSellerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surfaceColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Start Selling on Kasuwa',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your shop profile and reach thousands of customers in Jos and beyond.',
            style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CreateShopScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Create Your Shop'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, String? referralCode) {
    if (referralCode == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Referral Code',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                referralCode,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your code with friends. When they sign up, you both get bonuses!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final shareText =
                      'Join me on Kasuwa! Use my referral code to get a bonus: $referralCode. Download the app here: https://kasuwa.app/download';
                  Share.share(shareText);
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share My Code',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1)
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
