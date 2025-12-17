import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:kasuwa/screens/search_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:kasuwa/services/category_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/home_screen.dart';

// --- The Main UI Screen ---
class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  _BrowseProductsScreenState createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text('Discover',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [Tab(text: 'Categories'), Tab(text: 'Brands')],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoriesView(),
                  _buildBrandsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => SearchScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!)),
          child: Row(children: [
            Icon(Icons.search, color: AppTheme.textSecondary),
            SizedBox(width: 8),
            Text('Search products and brands...',
                style: TextStyle(color: AppTheme.textSecondary))
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.mainCategories.isEmpty) {
          return _buildLoadingSkeleton();
        }
        if (provider.mainCategories.isEmpty && !provider.isLoading) {
          return Center(
              child: Text("No categories found. Pull down to refresh."));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchCategories(forceRefresh: true),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryList(provider.mainCategories),
              _buildSubcategoryContent(provider.mainCategories),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallSubcategoryCard(SubCategory subcategory) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to products list for this subcategory
      },
      child: Container(
        width: 80, // Define a fixed width for each card
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1, // Creates a square aspect ratio for the image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: subcategory.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subcategory.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<MainCategory> categories) {
    return Container(
      width: 110,
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppTheme.primaryLight, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: isSelected ? null : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(categories[index].icon,
                      size: 28,
                      color: isSelected ? Colors.white : AppTheme.textPrimary),
                  const SizedBox(height: 8),
                  Text(categories[index].name,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryContent(List<MainCategory> mainCategories) {
    if (_selectedCategoryIndex >= mainCategories.length) {
      return Expanded(child: Center(child: CircularProgressIndicator()));
    }

    final selectedCategory = mainCategories[_selectedCategoryIndex];
    final currentSubcategories = selectedCategory.subcategories;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedCategory.name,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      IconButton(
                          icon: Icon(MdiIcons.filterVariant,
                              color: AppTheme.primaryColor),
                          onPressed: () {}),
                    ]),
              ),
              if (currentSubcategories.isEmpty)
                _buildEmptyState()
              else
                Wrap(
                  spacing: 16.0, // Horizontal space between cards
                  runSpacing: 16.0, // Vertical space between rows
                  children: currentSubcategories
                      .map((sub) => _buildSmallSubcategoryCard(sub))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Row(children: [
      Container(
          width: 110,
          child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (ctx, i) => Container(
                      height: 100,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)))))),
      Expanded(
          child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  padding: EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (ctx, i) => Container(
                      height: i.isEven ? 200 : 250,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))))),
    ]);
  }

  Widget _buildBrandsView() {
    /* ... unchanged mock data implementation ... */ return Center(
        child: Text("Brands View "));
  }

  Widget _buildEmptyState() {
    /* ... unchanged implementation ... */ return Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(MdiIcons.packageVariantRemove,
                  size: 60, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('Coming Soon!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              SizedBox(height: 8),
              Text('No subcategories have been added yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary))
            ])));
  }
}
