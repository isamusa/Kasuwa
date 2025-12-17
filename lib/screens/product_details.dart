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
import 'package:kasuwa/screens/shipping_address_screen.dart'; // Added for shipping
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
  Map<int, int> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ProductProvider>(context);
    if (provider.product != null) {
      _updateSelectedVariant(provider.product!);
    }
  }

  void _updateSelectedVariant(ProductDetail product) {
    // Logic for Simple Products (no attributes)
    if (product.attributes.isEmpty && product.variants.isNotEmpty) {
      if (mounted) setState(() => _selectedVariant = product.variants.first);
      return;
    }

    // Logic for Variable Products
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
            backgroundColor: Colors.green));
      }
    } else {
      // Variable Product Logic
      if (_selectedVariant == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select all options first.'),
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
            backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB), // Subtle off-white
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
      return Center(child: Text('Error: ${provider.error}'));
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

    // Calculate discount percentage
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
                // 1. Title
                Text(product.name,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppTheme.textColorPrimary)),

                const SizedBox(height: 12),

                // 2. Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormatter.format(salePrice ?? price),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor)),
                    const SizedBox(width: 10),
                    if (salePrice != null) ...[
                      Text(currencyFormatter.format(price),
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("-$discountPercent%",
                            style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      )
                    ]
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Selectors (Attributes + Quantity)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.attributes.isNotEmpty)
                        ...product.attributes
                            .map((attribute) =>
                                _buildAttributeSelector(context, attribute))
                            .toList(),
                      _buildStockStatus(context),
                      const Divider(height: 24),
                      _buildQuantitySelector(context),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Shipping Info
                _buildShippingInfoSection(context),

                const SizedBox(height: 20),

                // 5. Seller Info
                _buildSellerInfo(context, product.shop),

                const SizedBox(height: 20),

                // 6. Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(
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
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isDescriptionExpanded = !_isDescriptionExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _isDescriptionExpanded
                                  ? "Show Less"
                                  : "Read More",
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 7. Reviews
                _buildReviewsSection(product),

                const SizedBox(height: 24),

                // 8. Related Products
                if (product.relatedProducts.isNotEmpty)
                  _buildRelatedProducts(product.relatedProducts),

                const SizedBox(height: 40),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(attribute.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: attribute.options.map((option) {
              final isSelected =
                  provider.selectedOptions[attribute.id] == option.id;
              return InkWell(
                onTap: () => provider.selectOption(attribute.id, option.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: 1.5),
                  ),
                  child: Text(option.value,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500)),
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

    // Check limits
    final currentStock = provider.maxStock;
    final isAtMin = provider.quantity <= 1;
    final isAtMax = provider.quantity >= currentStock;

    // If no stock is available (or variant not selected), disable everything
    final isDisabled = currentStock == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Container(
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              // Minus Button
              IconButton(
                  icon: Icon(Icons.remove,
                      size: 20,
                      color: (isAtMin || isDisabled)
                          ? Colors.grey[400]
                          : Colors.black),
                  onPressed: (isAtMin || isDisabled)
                      ? null
                      : () => provider.setQuantity(provider.quantity - 1)),

              // Count Display
              SizedBox(
                width: 30,
                child: Center(
                  child: Text('${provider.quantity}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDisabled ? Colors.grey : Colors.black)),
                ),
              ),

              // Plus Button
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

    // Style constants
    final labelStyle = TextStyle(
        fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500);
    final contentStyle = const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87);

    if (!authProvider.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Login to see delivery options",
                        style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("Check availability for your location",
                        style:
                            TextStyle(color: Colors.blue[700], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue)
            ],
          ),
        ),
      );
    }

    if (provider.defaultAddress == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShippingAddressScreen()));
            provider.fetchProductDetails(provider.product!.id);
          },
          child: Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add a shipping address",
                        style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("To see delivery fees & times",
                        style:
                            TextStyle(color: Colors.orange[800], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange[800])
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Location
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    color: Colors.grey[500], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Deliver to:", style: labelStyle),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ShippingAddressScreen()));
                              provider
                                  .fetchProductDetails(provider.product!.id);
                            },
                            child: const Text("CHANGE",
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${provider.defaultAddress!.recipientName}, ${provider.defaultAddress!.fullAddress}",
                        style: contentStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          // Fee
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: Colors.grey[500], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Standard Delivery", style: labelStyle),
                      const SizedBox(height: 4),
                      if (provider.shippingFee != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(provider.estimatedDelivery ?? '1-3 Days',
                                style: contentStyle),
                            Text(
                              "₦${NumberFormat('#,##0').format(provider.shippingFee)}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
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
          expandedHeight: 400.0, // Taller image for impact
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
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
                    color: isFavorite ? Colors.red : Colors.black),
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

    // Filter out invalid images
    final validImages = images.where((img) => img.url.isNotEmpty).toList();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
              height: 450, // Matches AppBar height
              autoPlay: false,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              }),
          items: validImages
              .map((img) => CachedNetworkImage(
                  imageUrl: img.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (c, u) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, u, e) => const Icon(Icons.error)))
              .toList(),
        ),
        // DOT INDICATOR
        if (validImages.length > 1)
          Positioned(
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: validImages.asMap().entries.map((entry) {
                return Container(
                  width: _currentImageIndex == entry.key ? 12.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.5)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStockStatus(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final product = provider.product!;
    final selectedVariant = provider.selectedVariant;

    // FIX: If we are still verifying stock in background, show a "Checking..." state
    if (provider.isBackgroundLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey[600])),
            const SizedBox(width: 8),
            Text(
              "Verifying availability...",
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // ... (Rest of the logic remains the same as before) ...
    int stock = 0;
    if (product.attributes.isNotEmpty) {
      stock = selectedVariant?.stockQuantity ?? 0;
    } else {
      stock = product.stockQuantity ?? 0;
    }

    bool isAvailable = false;
    if (product.attributes.isNotEmpty) {
      if (selectedVariant != null) isAvailable = stock > 0;
    } else {
      isAvailable = stock > 0;
    }

    if (product.attributes.isNotEmpty && selectedVariant == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: isAvailable ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? Colors.green[700] : Colors.red[700],
              size: 16),
          const SizedBox(width: 8),
          Text(
            isAvailable ? "In Stock ($stock units)" : "Out of Stock",
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          CircleAvatar(
              radius: 24,
              backgroundImage:
                  hasLogo ? CachedNetworkImageProvider(shop.logoUrl!) : null,
              child: !hasLogo ? const Icon(Icons.storefront) : null,
              backgroundColor: Colors.grey[100]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sold by',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(shop.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShopProfileScreen(shopSlug: shop.slug))),
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Visit Store',
                style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductDetail product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('See All',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (product.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text("No reviews yet.",
                    style: TextStyle(color: Colors.grey[400])),
              ),
            )
          else ...[
            // Summary
            Row(
              children: [
                Text(product.avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarRating(
                        rating: product.avgRating, reviewCount: 0, size: 18),
                    const SizedBox(height: 4),
                    Text('${product.reviewsCount} verified reviews',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
            const Divider(height: 30),
            // Review List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: product.reviews.take(3).length, // Show top 3
              itemBuilder: (context, index) {
                return _buildReviewItem(product.reviews[index]);
              },
              separatorBuilder: (context, index) => const Divider(height: 24),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final hasUserImage =
        review.userImageUrl != null && review.userImageUrl!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: hasUserImage
                      ? CachedNetworkImageProvider(review.userImageUrl!)
                      : null,
                  child:
                      !hasUserImage ? const Icon(Icons.person, size: 16) : null,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 8),
                Text(review.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Text(timeago.format(DateTime.parse(review.createdAt)),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        StarRating(rating: review.rating.toDouble(), reviewCount: 0, size: 14),
        const SizedBox(height: 8),
        Text(review.comment,
            style:
                TextStyle(color: Colors.grey[800], height: 1.4, fontSize: 14)),
      ],
    );
  }

  Widget _buildRelatedProducts(List<HomeProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('You Might Also Like',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
    // Get provider to check background loading status
    final provider = Provider.of<ProductProvider>(context, listen: true);

    // Disable buttons if loading
    if (provider.isBackgroundLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null, // Disabled
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: null, // Disabled
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Loading...',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Standard Logic
    bool canProceed = false;
    if (product.attributes.isEmpty) {
      canProceed = (product.stockQuantity ?? 0) > 0;
    } else {
      canProceed =
          _selectedVariant != null && _selectedVariant!.stockQuantity > 0;
    }

    return Container(
      // ... (Rest of existing bottom bar styling and logic) ...
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      child: SafeArea(
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
                    foregroundColor: AppTheme.primaryColor),
                child: const Text('Add to Cart',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: canProceed
                    ? () => _handleConfirmation(isBuyNow: true)
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                child: const Text('Buy Now',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
            child: Column(children: [
          Container(height: 400, color: Colors.white),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 200, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 32, width: 150, color: Colors.white),
                  const SizedBox(height: 32),
                  Container(
                      height: 100, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 24),
                  Container(
                      height: 80, width: double.infinity, color: Colors.white),
                ],
              )),
        ])));
  }
}
