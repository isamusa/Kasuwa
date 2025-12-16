import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/shop_profile.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:kasuwa/providers/product_provider.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/screens/checkout_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/login_screen.dart';

// --- Main Page Widget ---
class ProductDetailsPage extends StatelessWidget {
  final int productId;
  final HomeProduct? product;

  const ProductDetailsPage({super.key, required this.productId, this.product});

  @override
  Widget build(BuildContext context) {
    // The provider is created here, scoped to this screen.
    // Data fetching is initiated immediately in the 'create' method.
    return ChangeNotifierProvider(
      create: (context) => ProductProvider(
        Provider.of<AuthProvider>(context, listen: false),
        Provider.of<CheckoutProvider>(context, listen: false),
      )..fetchProductDetails(productId, initialData: product),
      child: const _ProductDetailsView(),
    );
  }
}

// THE FIX: The main view is now a single, correctly structured StatefulWidget.
class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView();

  @override
  __ProductDetailsViewState createState() => __ProductDetailsViewState();
}

class __ProductDetailsViewState extends State<_ProductDetailsView> {
  int _currentImageIndex = 0;
  Map<int, int> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When the provider gets the product data, we update our local state.
    final provider = Provider.of<ProductProvider>(context);
    if (provider.product != null) {
      _updateSelectedVariant(provider.product!);
    }
  }

  void _updateSelectedVariant(ProductDetail product) {
    // If the product has no attributes, it's a simple product.
    // We check if it has a default variant (often used for base price/stock).
    if (product.attributes.isEmpty && product.variants.isNotEmpty) {
      if (mounted) setState(() => _selectedVariant = product.variants.first);
      return;
    }

    // If it has attributes, we proceed with the variant selection logic.
    if (_selectedOptions.length != product.attributes.length) {
      if (mounted) setState(() => _selectedVariant = null);
      return;
    }

    final selectedOptionIds = _selectedOptions.values.toSet();
    for (var variant in product.variants) {
      final variantOptionIds =
          variant.attributeOptions.map((opt) => opt.id).toSet();
      if (variantOptionIds.length == selectedOptionIds.length &&
          variantOptionIds.every(selectedOptionIds.contains)) {
        if (mounted) setState(() => _selectedVariant = variant);
        return;
      }
    }
    if (mounted) setState(() => _selectedVariant = null);
  }

  void _handleConfirmation({required bool isBuyNow}) {
    final product =
        Provider.of<ProductProvider>(context, listen: false).product!;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // This logic now correctly handles both simple and variant products.
    if (product.attributes.isEmpty) {
      // --- LOGIC FOR SIMPLE PRODUCTS ---
      if (isBuyNow) {
        final itemToCheckout = [
          CheckoutCartItem(
            productId: product.id,
            imageUrl: product.images.isNotEmpty ? product.images.first.url : '',
            name: product.name,
            price: product.salePrice ?? product.price!,
            quantity: _quantity,
          )
        ];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CheckoutScreen(itemsToCheckout: itemToCheckout)));
      } else {
        // cartProvider.addProductToCart(product.id, _quantity);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: Colors.green));
      }
    } else {
      // --- LOGIC FOR PRODUCTS WITH VARIANTS ---
      if (_selectedVariant == null) return;
      final variantDescription = _selectedVariant!.attributeOptions
          .map((opt) => '${opt.attributeName}: ${opt.value}')
          .join(', ');

      if (isBuyNow) {
        final itemToCheckout = [
          CheckoutCartItem(
            productId: product.id,
            imageUrl: product.images.isNotEmpty ? product.images.first.url : '',
            name: product.name,
            price: _selectedVariant!.salePrice ?? _selectedVariant!.price,
            quantity: _quantity,
            variantDescription: variantDescription,
          )
        ];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CheckoutScreen(itemsToCheckout: itemToCheckout)));
      } else {
        // cartProvider.addVariantToCart(_selectedVariant!.id, _quantity);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${product.name} (${variantDescription}) added to cart!'),
            backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: _buildBody(provider),
          bottomSheet: provider.product != null
              ? _buildBottomBar(provider.product!)
              : null,
        );
      },
    );
  }

  Widget _buildBody(ProductProvider provider) {
    if (provider.isLoading && provider.product == null) {
      return _buildLoadingState();
    }
    if (provider.error != null && provider.product == null) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    if (provider.product == null) {
      return Center(child: Text('Product not found.'));
    }
    return _buildContent(provider.product!);
  }

  Widget _buildBottomBar(ProductDetail product) {
    bool canProceed = false;
    if (product.attributes.isEmpty) {
      canProceed = product.stockQuantity! > 0;
    } else {
      canProceed =
          _selectedVariant != null && _selectedVariant!.stockQuantity > 0;
    }

    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration:
          BoxDecoration(color: AppTheme.cardBackgroundColor, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2))
      ]),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canProceed
                  ? () => _handleConfirmation(isBuyNow: false)
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledForegroundColor: Colors.grey,
              ),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  canProceed ? () => _handleConfirmation(isBuyNow: true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Buy Now',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProductDetail product) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final price = _selectedVariant?.price ?? product.price;
    final salePrice = _selectedVariant?.salePrice ?? product.salePrice;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, product),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColorPrimary)),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(currencyFormatter.format(salePrice ?? price),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                    SizedBox(width: 12),
                    if (salePrice != null)
                      Text(currencyFormatter.format(price),
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.textColorSecondary,
                              fontSize: 16)),
                  ],
                ),
                SizedBox(height: 24),
                if (product.attributes.isNotEmpty)
                  ...product.attributes
                      .map((attribute) =>
                          _buildAttributeSelector(context, attribute))
                      .toList(),
                SizedBox(height: 8),
                _buildStockStatus(context),
                SizedBox(height: 16),
                _buildQuantitySelector(context),
                Divider(height: 32),
                _buildShippingInfoSection(context),
                Divider(height: 32),
                _buildSellerInfo(context, product.shop),
                Divider(height: 32),
                Text('Description',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(product.description,
                    style: TextStyle(
                        fontSize: 14, height: 1.5, color: Colors.grey[700])),
                SizedBox(height: 24),
                _buildReviewsSection(product),
                SizedBox(height: 24),
                if (product.relatedProducts.isNotEmpty)
                  _buildRelatedProducts(product.relatedProducts),
                SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSelector(
      BuildContext context, ProductAttribute attribute) {
    final provider = Provider.of<ProductProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(attribute.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: attribute.options.map((option) {
            final isSelected =
                provider.selectedOptions[attribute.id] == option.id;
            return ChoiceChip(
              label: Text(option.value),
              selected: isSelected,
              onSelected: (selected) {
                provider.selectOption(
                    attribute.id, selected ? option.id : null);
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle:
                  TextStyle(color: isSelected ? Colors.white : Colors.black),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStockStatus(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context); // Get provider here

    final product = provider.product!;
    final selectedVariant = provider.selectedVariant;

    if (product.attributes.isNotEmpty) {
      if (selectedVariant == null &&
          provider.selectedOptions.length == product.attributes.length) {
        return const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Combination not available',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ]);
      }
      if (selectedVariant != null) {
        final bool inStock = selectedVariant.stockQuantity > 0;
        return Row(children: [
          Icon(inStock ? Icons.check_circle_outline : Icons.error_outline,
              color: inStock ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
              inStock
                  ? 'In Stock (${selectedVariant.stockQuantity} available)'
                  : 'Out of Stock',
              style: TextStyle(
                  color: inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold)),
        ]);
      }
    } else {
      final bool inStock = (product.stockQuantity ?? 0) > 0;
      return Row(
        children: [
          Icon(inStock ? Icons.check_circle_outline : Icons.error_outline,
              color: inStock ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
              inStock
                  ? 'In Stock (${product.stockQuantity} available)'
                  : 'Out of Stock',
              style: TextStyle(
                  color: inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Container();
  }

  Widget _buildQuantitySelector(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    return Row(
      children: [
        const Text("Quantity:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => provider.setQuantity(provider.quantity - 1)),
              Text('${provider.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => provider.setQuantity(provider.quantity + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProductDetail product) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, child) {
        final isFavorite = wishlist.isFavorite(product.id);
        return SliverAppBar(
          expandedHeight: 300.0,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back, color: AppTheme.textColorPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share_outlined, color: AppTheme.primaryColor),
              onPressed: () {
                // Construct the shareable URL
                final url = '${AppConfig.baseUrl}/products/${product.slug}';
                Share.share('Check out this product on Kasuwa: $url');
              },
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppTheme.primaryColor),
              onPressed: () {
                final homeProduct = HomeProduct(
                    id: product.id,
                    name: product.name,
                    price: product.price!,
                    salePrice: product.salePrice,
                    avgRating: product.avgRating,
                    reviewsCount: product.reviewsCount,
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first.url
                        : '');
                wishlist.toggleWishlist(homeProduct);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageCarousel(product.images),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel(List<ProductImage> images) {
    if (images.isEmpty) {
      return Container(
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported,
              size: 80, color: Colors.grey[400]));
    }
    return CarouselSlider(
      options: CarouselOptions(
          height: 300,
          autoPlay: false,
          viewportFraction: 1.0,
          onPageChanged: (index, reason) {
            // This state is purely visual and can remain in the UI
          }),
      items: images
          .map((img) => CachedNetworkImage(
              imageUrl: img.url,
              fit: BoxFit.cover,
              placeholder: (c, u) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (c, u, e) => const Icon(Icons.error)))
          .toList(),
    );
  }

  Widget _buildSellerInfo(BuildContext context, ProductShop shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sold By',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              radius: 25,
              backgroundImage: shop.logoUrl != null
                  ? CachedNetworkImageProvider(shop.logoUrl!)
                  : null,
              child: shop.logoUrl == null ? const Icon(Icons.storefront) : null,
              backgroundColor: Colors.grey[200]),
          title: Text(shop.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: OutlinedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShopProfileScreen(shopSlug: shop.slug))),
            child: const Text('Visit Store'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(ProductDetail product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ratings & Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (product.reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text("No reviews yet for this product.",
                  style: TextStyle(color: Colors.grey[600])),
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Text('${product.avgRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(
                          rating: product.avgRating,
                          reviewCount: product.reviewsCount,
                          size: 20),
                      const SizedBox(height: 4),
                      Text('Based on ${product.reviewsCount} reviews',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
              const Divider(height: 32),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: product.reviews.length,
                itemBuilder: (context, index) {
                  return _buildReviewItem(product.reviews[index]);
                },
                separatorBuilder: (context, index) => const Divider(height: 24),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: review.userImageUrl != null
                  ? CachedNetworkImageProvider(review.userImageUrl!)
                  : null,
              child:
                  review.userImageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(timeago.format(DateTime.parse(review.createdAt)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            StarRating(
                rating: review.rating.toDouble(), reviewCount: 0, size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Text(review.comment,
            style: TextStyle(color: Colors.grey[800], height: 1.4)),
      ],
    );
  }

  Widget _buildRelatedProducts(List<HomeProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('You Might Also Like',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                child: ModernProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfoSection(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ProductProvider>(context);
    // Case 1: User is a guest.
    if (!authProvider.isAuthenticated) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.login, color: AppTheme.primaryColor),
          title: Text("Login to see shipping options"),
          subtitle: Text("Get delivery estimates for your location."),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
        ),
      );
    }

    // Case 2: User is logged in, but has no address.
    if (provider.defaultAddress == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.add_location_alt_outlined,
              color: AppTheme.primaryColor),
          title: Text("Add a shipping address"),
          subtitle: Text("To see delivery options and fees"),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to Add Address Screen
          },
        ),
      );
    }

    // Case 3: User is logged in and has an address.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
          title: Text(
              "Deliver to ${provider.defaultAddress!.recipientName} - ${provider.defaultAddress!}"),
          subtitle: Text(provider.defaultAddress!.fullAddress,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: TextButton(
              onPressed: () {/* Change Address */}, child: Text("Change")),
        ),
        SizedBox(height: 8),
        if (provider.shippingFee != null)
          Card(
            color: Colors.grey[100],
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.delivery_dining_outlined,
                  color: AppTheme.primaryColor),
              title: Text(
                  "Delivery Fee: ₦${provider.shippingFee!.toStringAsFixed(2)}"),
              subtitle: Text(
                  "Estimated Delivery: ${provider.estimatedDelivery ?? 'N/A'}"),
            ),
          )
      ],
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
            child: Column(children: [
          Container(height: 350, color: Colors.white),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 30, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 20, width: 200, color: Colors.white),
                  const SizedBox(height: 32),
                  Container(
                      height: 60, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 32),
                  Container(
                      height: 100, width: double.infinity, color: Colors.white),
                ],
              )),
        ])));
  }
}
