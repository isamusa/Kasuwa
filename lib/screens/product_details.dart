import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/shop_profile.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/providers/product_provider.dart';
import 'package:kasuwa/models/product_detail_model.dart';
import 'package:kasuwa/screens/checkout_screen.dart';
import 'package:kasuwa/screens/shipping_address_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/providers/home_provider.dart'; // For HomeProduct
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/login_screen.dart';

// --- Reusable Star Rating Widget (Local to this file or import if global) ---
class _DetailsStarRating extends StatelessWidget {
  final double rating;
  final double size;
  const _DetailsStarRating({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index >= rating) {
          icon = Icons.star_border_rounded;
        } else if (index > rating - 0.5 && index < rating) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_rounded;
        }
        return Icon(icon, color: Colors.amber, size: size);
      }),
    );
  }
}

// --- Main Page Widget ---
class ProductDetailsPage extends StatelessWidget {
  final int productId;
  final HomeProduct? product;

  const ProductDetailsPage({super.key, required this.productId, this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductProvider(
        Provider.of<AuthProvider>(context, listen: false),
        Provider.of<CheckoutProvider>(context, listen: false),
      )..fetchProductDetails(productId, initialData: product),
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView();

  @override
  __ProductDetailsViewState createState() => __ProductDetailsViewState();
}

class __ProductDetailsViewState extends State<_ProductDetailsView> {
  int _currentImageIndex = 0;
  // ignore: prefer_final_fields
  Map<int, int> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ProductProvider>(context);
    if (provider.product != null) {
      // Defer state update to avoid build conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateSelectedVariant(provider.product!);
      });
    }
  }

  void _updateSelectedVariant(ProductDetail product) {
    // 1. Simple Product
    if (product.attributes.isEmpty && product.variants.isNotEmpty) {
      if (mounted && _selectedVariant == null) {
        setState(() => _selectedVariant = product.variants.first);
      }
      return;
    }

    // 2. Variable Product - check if all options selected
    if (_selectedOptions.length != product.attributes.length) {
      if (mounted && _selectedVariant != null) {
        setState(() => _selectedVariant = null);
      }
      return;
    }

    // 3. Find matching variant
    final selectedOptionIds = _selectedOptions.values.toSet();
    ProductVariant? foundVariant;

    for (var variant in product.variants) {
      final variantOptionIds =
          variant.attributeOptions.map((opt) => opt.id).toSet();
      if (variantOptionIds.length == selectedOptionIds.length &&
          variantOptionIds.every(selectedOptionIds.contains)) {
        foundVariant = variant;
        break;
      }
    }

    if (mounted && _selectedVariant != foundVariant) {
      setState(() => _selectedVariant = foundVariant);
    }
  }

  void _handleConfirmation({required bool isBuyNow}) {
    final product =
        Provider.of<ProductProvider>(context, listen: false).product!;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (product.attributes.isEmpty) {
      // Simple Product Logic
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
        cartProvider.addProductToCart(product.id, _quantity);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${product.name} added to cart!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor));
      }
    } else {
      // Variable Product Logic
      if (_selectedVariant == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select all options first.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange));
        return;
      }

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
        cartProvider.addVariantToCart(_selectedVariant!.id, _quantity);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${product.name} ($variantDescription) added!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor));
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
          bottomNavigationBar: provider.product != null
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}',
                style: TextStyle(color: Colors.grey[700])),
            TextButton(
              onPressed: () =>
                  provider.fetchProductDetails(provider.product?.id ?? 0),
              child: const Text("Retry"),
            )
          ],
        ),
      );
    }
    if (provider.product == null) {
      return const Center(child: Text('Product not found.'));
    }
    return _buildContent(provider.product!);
  }

  Widget _buildContent(ProductDetail product) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final price = _selectedVariant?.price ?? product.price;
    final salePrice = _selectedVariant?.salePrice ?? product.salePrice;

    // Calculate discount
    int discountPercent = 0;
    if (salePrice != null && price != null && price > 0) {
      discountPercent = (((price - salePrice) / price) * 100).round();
    }

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, product),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title & Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DetailsStarRating(rating: product.avgRating, size: 16),
                    const SizedBox(width: 8),
                    Text('${product.avgRating.toStringAsFixed(1)} ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('(${product.reviewsCount} reviews)',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Price Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormatter.format(salePrice ?? price),
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 10),
                    if (salePrice != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(currencyFormatter.format(price),
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("-$discountPercent%",
                            style: const TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      )
                    ]
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Options Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.attributes.isNotEmpty)
                        ...product.attributes
                            .map((attribute) =>
                                _buildAttributeSelector(context, attribute))
                            .toList(),
                      _buildStockStatus(context),
                      const Divider(height: 30),
                      _buildQuantitySelector(context),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Shipping & Seller
                _buildShippingInfoSection(context),
                const SizedBox(height: 16),
                _buildSellerInfo(context, product.shop),

                const SizedBox(height: 24),

                // 5. Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      product.description,
                      style: TextStyle(
                          fontSize: 15, height: 1.6, color: Colors.grey[800]),
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (product.description.length > 200)
                      GestureDetector(
                        onTap: () => setState(() =>
                            _isDescriptionExpanded = !_isDescriptionExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _isDescriptionExpanded ? "Show Less" : "Read More",
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                  ],
                ),

                const SizedBox(height: 30),

                // 6. Reviews
                _buildReviewsSection(product),

                const SizedBox(height: 30),

                // 7. Related
                if (product.relatedProducts.isNotEmpty)
                  _buildRelatedProducts(product.relatedProducts),

                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildAttributeSelector(
      BuildContext context, ProductAttribute attribute) {
    final provider = Provider.of<ProductProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(attribute.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              if (provider.selectedOptions.containsKey(attribute.id))
                Text(
                  attribute.options
                      .firstWhere(
                          (o) => o.id == provider.selectedOptions[attribute.id])
                      .value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: attribute.options.map((option) {
              final isSelected =
                  provider.selectedOptions[attribute.id] == option.id;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: InkWell(
                  onTap: () => provider.selectOption(attribute.id, option.id),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    child: Text(option.value,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final currentStock = provider.maxStock;
    final isAtMin = provider.quantity <= 1;
    final isAtMax = provider.quantity >= currentStock;
    final isDisabled = currentStock == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Container(
          decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              IconButton(
                  icon: Icon(Icons.remove,
                      size: 20,
                      color: (isAtMin || isDisabled)
                          ? Colors.grey[400]
                          : Colors.black),
                  onPressed: (isAtMin || isDisabled)
                      ? null
                      : () => provider.setQuantity(provider.quantity - 1)),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('${provider.quantity}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDisabled ? Colors.grey : Colors.black)),
              ),
              IconButton(
                  icon: Icon(Icons.add,
                      size: 20,
                      color: (isAtMax || isDisabled)
                          ? Colors.grey[400]
                          : Colors.black),
                  onPressed: (isAtMax || isDisabled)
                      ? null
                      : () => provider.setQuantity(provider.quantity + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfoSection(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ProductProvider>(context);

    // Common container style
    BoxDecoration boxDecoration(Color color, Color borderColor) =>
        BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        );

    if (!authProvider.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: boxDecoration(Colors.blue.shade50, Colors.blue.shade100),
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Log in to view delivery options",
                        style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold)),
                    Text("We need your location to calculate shipping",
                        style: TextStyle(
                            color: Colors.blue.shade700, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.blue.shade700)
            ],
          ),
        ),
      );
    }

    // Authenticated View
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Address Selector
          InkWell(
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ShippingAddressScreen()));
              provider.fetchProductDetails(provider.product!.id);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.defaultAddress != null) ...[
                          Text(
                            provider.defaultAddress!.recipientName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(provider.defaultAddress!.toString(),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ] else
                          const Text("Add a shipping address",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          // Cost
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.delivery_dining_outlined, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Standard Delivery",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      if (provider.shippingFee != null)
                        Text(provider.estimatedDelivery ?? '1-3 Days',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                if (provider.shippingFee != null)
                  Text("₦${NumberFormat('#,##0').format(provider.shippingFee)}",
                      style: const TextStyle(fontWeight: FontWeight.bold))
                else if (provider.defaultAddress != null)
                  const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  const Text("--", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProductDetail product) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, child) {
        final isFavorite = wishlist.isFavorite(product.id);
        return SliverAppBar(
          expandedHeight: 450.0,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          // Custom Leading to ensure visibility
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () {
                  final url = '${AppConfig.baseUrl}/products/${product.slug}';
                  Share.share('Check out this product: $url');
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppTheme.secondaryColor : Colors.black),
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
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                _buildImageCarousel(product.images, product.id),
                // Gradient for visibility of status bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel(List<ProductImage> images, int productId) {
    if (images.isEmpty) {
      return Container(
          color: Colors.grey[100],
          child: Icon(Icons.image_not_supported_outlined,
              size: 80, color: Colors.grey[400]));
    }

    final validImages = images.where((img) => img.url.isNotEmpty).toList();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
              height: 500, // Taller
              autoPlay: false,
              viewportFraction: 1.0,
              enableInfiniteScroll: validImages.length > 1,
              onPageChanged: (index, reason) {
                setState(() => _currentImageIndex = index);
              }),
          items: validImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;

            // Only Hero the first image to match Home Screen transition
            Widget imageWidget = CachedNetworkImage(
                imageUrl: img.url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (c, u) => Container(color: Colors.grey[100]),
                errorWidget: (c, u, e) => const Icon(Icons.error));

            if (index == 0) {
              return Hero(
                tag: 'product_$productId',
                child: imageWidget,
              );
            }
            return imageWidget;
          }).toList(),
        ),
        if (validImages.length > 1)
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: validImages.asMap().entries.map((entry) {
                  return Container(
                    width: _currentImageIndex == entry.key ? 10.0 : 6.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockStatus(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final product = provider.product!;
    final selectedVariant = provider.selectedVariant;

    if (provider.isBackgroundLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text("Verifying stock...",
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    int stock = product.attributes.isNotEmpty
        ? (selectedVariant?.stockQuantity ?? 0)
        : (product.stockQuantity ?? 0);

    bool isAvailable = stock > 0;

    // Don't show anything if waiting for selection
    if (product.attributes.isNotEmpty && selectedVariant == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color:
              isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAvailable ? Icons.check_circle_outline : Icons.highlight_off,
              color: isAvailable ? Colors.green[700] : Colors.red[700],
              size: 16),
          const SizedBox(width: 6),
          Text(
            isAvailable ? "In Stock ($stock available)" : "Out of Stock",
            style: TextStyle(
                color: isAvailable ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context, ProductShop shop) {
    final hasLogo = shop.logoUrl != null && shop.logoUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(
              radius: 20,
              backgroundImage:
                  hasLogo ? CachedNetworkImageProvider(shop.logoUrl!) : null,
              child: !hasLogo ? const Icon(Icons.storefront, size: 20) : null,
              backgroundColor: Colors.grey[100]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sold by",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                Text(shop.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShopProfileScreen(shopSlug: shop.slug))),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Visit Store', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductDetail product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Reviews (${product.reviewsCount})",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (product.reviews.isNotEmpty)
              TextButton(onPressed: () {}, child: const Text("See All"))
          ],
        ),
        if (product.reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text("No reviews yet",
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.reviews.take(3).length,
            itemBuilder: (context, index) =>
                _buildReviewItem(product.reviews[index]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
          )
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (review.userImageUrl != null)
                        ? CachedNetworkImageProvider(review.userImageUrl!)
                        : null,
                    child: (review.userImageUrl == null)
                        ? const Icon(Icons.person, size: 16, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(review.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(timeago.format(DateTime.parse(review.createdAt)),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          _DetailsStarRating(rating: review.rating.toDouble(), size: 14),
          const SizedBox(height: 8),
          Text(review.comment,
              style: TextStyle(
                  color: Colors.grey[800], height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts(List<HomeProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('You Might Also Like',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: ModernProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ProductDetail product) {
    final provider = Provider.of<ProductProvider>(context, listen: true);

    // Standard Check
    bool canProceed = false;
    if (product.attributes.isEmpty) {
      canProceed = (product.stockQuantity ?? 0) > 0;
    } else {
      canProceed =
          _selectedVariant != null && _selectedVariant!.stockQuantity > 0;
    }

    if (provider.isBackgroundLoading) canProceed = false;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 32), // Extra bottom padding for safe area
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5))
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
                side: BorderSide(
                    color: canProceed
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add to Cart',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canProceed ? AppTheme.primaryColor : Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  canProceed ? () => _handleConfirmation(isBuyNow: true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text('Buy Now',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // App Bar Placeholder
          SliverAppBar(
            expandedHeight: 450.0,
            pinned: true,
            backgroundColor: Colors.white,
            leading: const SizedBox(), // Hide back button in shimmer
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.white),
            ),
          ),
          // Body Placeholder
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                      height: 24,
                      width: double.infinity,
                      margin: const EdgeInsets.only(right: 60),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  // Price
                  Container(
                      height: 32,
                      width: 150,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 24),
                  // Options Box
                  Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 24),
                  // Description lines
                  Container(
                      height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(
                      height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 200, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
