import 'package:flutter/material.dart';
import 'package:kasuwa/screens/search_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/product_list_screen.dart';
import 'package:kasuwa/screens/home_screen.dart'; // Required for back navigation
import 'package:kasuwa/config/app_config.dart';

// Helper for safe image URLs
String storageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http') || path.startsWith('https')) {
    return path;
  }
  return '${AppConfig.baseUrl}/storage/$path';
}

class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Handle System Back Gesture -> Go Home
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedHomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: _buildHeaderSearch(),
          automaticallyImplyLeading: false, // Hides default back button
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: Colors.grey[200], height: 1.0),
          ),
        ),
        body: Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            // Loading State
            if (provider.isLoading && provider.mainCategories.isEmpty) {
              return _buildLoading();
            }

            // Error / Empty State
            if (provider.mainCategories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No categories found",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () =>
                          provider.fetchCategories(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    )
                  ],
                ),
              );
            }

            final mainCategories = provider.mainCategories;
            // Safety check for index out of bounds
            if (_selectedIndex >= mainCategories.length) _selectedIndex = 0;
            final selectedCategory = mainCategories[_selectedIndex];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LEFT SIDEBAR (Main Categories) ---
                Container(
                  width: 110,
                  color: const Color(0xFFF7F8FA),
                  child: ListView.separated(
                    itemCount: mainCategories.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index) {
                      return _SidebarItem(
                        category: mainCategories[index],
                        isSelected: _selectedIndex == index,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),

                // --- RIGHT CONTENT (Subcategories) ---
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                selectedCategory.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProductListScreen(
                                            categoryId: selectedCategory.id,
                                            categoryName:
                                                selectedCategory.name)));
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                              child: const Text("View All",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Subcategories Grid
                        if (selectedCategory.subcategories.isEmpty)
                          _buildEmptySubCategoryState(selectedCategory)
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: selectedCategory.subcategories.length,
                            itemBuilder: (context, index) {
                              final sub = selectedCategory.subcategories[index];
                              return _SubCategoryCard(subCategory: sub);
                            },
                          ),

                        const SizedBox(height: 80), // Bottom Padding
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSearch() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 22, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Search categories, products...",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubCategoryState(dynamic category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.layers_clear_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No subcategories in ${category.name}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductListScreen(
                          categoryId: category.id,
                          categoryName: category.name)));
            },
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor),
            child: const Text("Browse All Products"),
          )
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Loading
        Container(
          width: 110,
          color: const Color(0xFFF7F8FA),
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 60,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        // Grid Loading
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(height: 20, width: 150, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: List.generate(
                          6,
                          (index) => Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12)),
                              )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET: Sidebar Item ---
class _SidebarItem extends StatelessWidget {
  final dynamic category;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.white : Colors.transparent,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Active Indicator Line
              Container(
                width: 4,
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // You can add Icons here if your API returns them
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET: SubCategory Card ---
class _SubCategoryCard extends StatelessWidget {
  final dynamic subCategory;

  const _SubCategoryCard({required this.subCategory});

  @override
  Widget build(BuildContext context) {
    final imageUrl = storageUrl(subCategory.imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductListScreen(
                    categoryId: subCategory.id,
                    categoryName: subCategory.name)));
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[50],
                    child: const Center(
                        child: Icon(Icons.image, color: Colors.grey)),
                  ),
                  errorWidget: (c, e, s) => Container(
                    color: Colors.grey[50],
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subCategory.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
