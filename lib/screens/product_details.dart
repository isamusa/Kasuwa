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
import 'package:kasuwa/providers/home_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/login_screen.dart';

class _DetailsStarRating extends StatelessWidget {
  final double rating;
  final double size;
  const _DetailsStarRating({required this.rating, this.size = 12});

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<CheckoutProvider>(context, listen: false).fetchAddresses();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ProductProvider>(context);
    if (provider.product != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateSelectedVariant(provider.product!);
      });
    }
  }

  void _updateSelectedVariant(ProductDetail product) {
    // 1. Simple Product Check
    if (product.attributes.isEmpty && product.variants.isNotEmpty) {
      if (mounted && _selectedVariant == null) {
        setState(() => _selectedVariant = product.variants.first);
      }
      return;
    }

    // 2. If selections are incomplete, clear variant
    if (Provider.of<ProductProvider>(context, listen: false)
            .selectedOptions
            .length !=
        product.attributes.length) {
      if (mounted && _selectedVariant != null) {
        setState(() => _selectedVariant = null);
      }
      return;
    }

    // 3. Find matching variant based on ALL selections
    final selectedMap =
        Provider.of<ProductProvider>(context, listen: false).selectedOptions;
    final selectedOptionIds = selectedMap.values.toSet();
    ProductVariant? foundVariant;

    for (var variant in product.variants) {
      final variantOptionIds =
          variant.attributeOptions.map((opt) => opt.id).toSet();
      // Check if variant options match selected options exactly
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Login Required"),
          content: const Text(
              "You need to be logged in to add items to cart or buy."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text("Login",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final product =
        Provider.of<ProductProvider>(context, listen: false).product!;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Variable Product Logic
    if (product.attributes.isNotEmpty) {
      if (_selectedVariant == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select all available options.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange));
        return;
      }
      if (_selectedVariant!.stockQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This item is currently out of stock.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red));
        return;
      }
    } else {
      // Simple Product Logic
      if ((product.stockQuantity ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This item is out of stock.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red));
        return;
      }
    }

    // Prepare Checkout Item
    final price = _selectedVariant?.salePrice ??
        _selectedVariant?.price ??
        product.salePrice ??
        product.price!;

    final variantDesc = _selectedVariant?.attributeOptions
        .map((opt) => '${opt.attributeName}: ${opt.value}')
        .join(', ');

    if (isBuyNow) {
      final itemToCheckout = [
        CheckoutCartItem(
          productId: product.id,
          imageUrl: product.images.isNotEmpty ? product.images.first.url : '',
          name: product.name,
          price: price,
          quantity: _quantity,
          variantDescription: variantDesc,
        )
      ];
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CheckoutScreen(itemsToCheckout: itemToCheckout)));
    } else {
      if (product.attributes.isNotEmpty && _selectedVariant != null) {
        cartProvider.addVariantToCart(_selectedVariant!.id, _quantity);
      } else {
        cartProvider.addProductToCart(product.id, _quantity);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added to cart!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
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

    int discountPercent = 0;
    if (salePrice != null && price != null && price > 0) {
      discountPercent = (((price - salePrice) / price) * 100).round();
    }

    // Need to trigger variant update when attributes change
    // This is handled by didChangeDependencies mostly, but safe to check here

    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, product),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Price & Title
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currencyFormatter.format(salePrice ?? price),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: -0.5),
                        ),
                        if (salePrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            currencyFormatter.format(price),
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                                fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text("-$discountPercent%",
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _DetailsStarRating(rating: product.avgRating, size: 14),
                        const SizedBox(width: 6),
                        Text('${product.avgRating.toStringAsFixed(1)} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('(${product.reviewsCount} reviews)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. Options / Variants
              if (product.attributes.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...product.attributes
                          .map((attribute) =>
                              _buildAttributeSelector(context, attribute))
                          .toList(),
                      // Stock Status Indicator
                      _buildStockStatus(context),
                      const SizedBox(height: 16),
                      // Quantity Selector
                      _buildQuantitySelector(context),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // 3. Shipping
              _buildShippingInfoSection(context),

              const SizedBox(height: 8),

              // 4. Seller
              _buildSellerInfo(context, product.shop),

              const SizedBox(height: 8),

              // 5. Description
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.grey[800]),
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (product.description.length > 150)
                      GestureDetector(
                        onTap: () => setState(() =>
                            _isDescriptionExpanded = !_isDescriptionExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isDescriptionExpanded
                                    ? "Show Less"
                                    : "Read More",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              Icon(
                                  _isDescriptionExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[600])
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 6. Reviews Preview
              _buildReviewsSection(product),

              const SizedBox(height: 8),

              // 7. Related
              if (product.relatedProducts.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildRelatedProducts(product.relatedProducts),
                ),

              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGIC: Stock Status Widget ---
  Widget _buildStockStatus(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final product = provider.product!;
    final selectedVariant = _selectedVariant; // Local state updated by logic

    // 1. Check if user has selected ALL attributes
    final allSelected =
        provider.selectedOptions.length == product.attributes.length;

    // 2. Logic to determine display
    String text;
    Color color;
    IconData icon;

    if (!allSelected) {
      text = "Select Options to see stock";
      color = Colors.grey;
      icon = Icons.info_outline;
    } else if (selectedVariant == null) {
      // All options selected, but no matching variant found in list
      text = "Combination Unavailable";
      color = Colors.red;
      icon = Icons.block;
    } else if (selectedVariant.stockQuantity <= 0) {
      text = "Out of Stock";
      color = Colors.red;
      icon = Icons.highlight_off;
    } else {
      text = "In Stock (${selectedVariant.stockQuantity} items)";
      color = Colors.green;
      icon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // --- LOGIC: Bottom Bar ---
  Widget _buildBottomBar(ProductDetail product) {
    final provider = Provider.of<ProductProvider>(context, listen: true);

    // Determine if actions should be enabled
    bool isActionEnabled = false;

    if (product.attributes.isEmpty) {
      // Simple product
      isActionEnabled = (product.stockQuantity ?? 0) > 0;
    } else {
      // Variable product
      // Must have selected variant AND that variant must have stock
      if (_selectedVariant != null && _selectedVariant!.stockQuantity > 0) {
        isActionEnabled = true;
      }
    }

    if (provider.isBackgroundLoading) isActionEnabled = false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, color: Colors.grey),
                Text("Store",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                Text("Cart",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isActionEnabled
                          ? () => _handleConfirmation(isBuyNow: false)
                          : null, // Disable if no stock
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD180),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(24))),
                      ),
                      child: const Text('Add to Cart',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isActionEnabled
                          ? () => _handleConfirmation(isBuyNow: true)
                          : null, // Disable if no stock
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(24))),
                      ),
                      child: const Text('Buy Now',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Unchanged Helper Widgets ---
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
              Text("${attribute.name}: ",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              if (provider.selectedOptions.containsKey(attribute.id))
                Text(
                  attribute.options
                      .firstWhere(
                          (o) => o.id == provider.selectedOptions[attribute.id])
                      .value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: attribute.options.map((option) {
              final isSelected =
                  provider.selectedOptions[attribute.id] == option.id;
              return InkWell(
                onTap: () {
                  provider.selectOption(attribute.id, option.id);
                  // Manually check for variant update after state change
                  // Note: In strict MVVM, this logic resides in Provider,
                  // but here we are mixing setState for local UI logic.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateSelectedVariant(provider.product!);
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent),
                  ),
                  child: Text(option.value,
                      style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12)),
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
    // Use selected variant stock if available, else product stock
    final currentStock =
        _selectedVariant?.stockQuantity ?? provider.product!.stockQuantity ?? 0;
    final isDisabled = currentStock == 0;

    return Row(
      children: [
        const Text("Quantity",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          height: 32,
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                  onPressed: (provider.quantity <= 1 || isDisabled)
                      ? null
                      : () => provider.setQuantity(provider.quantity - 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${provider.quantity}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                  onPressed: (provider.quantity >= currentStock || isDisabled)
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

    if (!authProvider.isAuthenticated) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.local_shipping_outlined,
                color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Login to see shipping options",
                  style: TextStyle(fontSize: 13, color: Colors.blue)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShippingAddressScreen()));
          provider.fetchProductDetails(provider.product!.id);
        },
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.defaultAddress != null) ...[
                    Row(
                      children: [
                        const Text("Deliver to: ",
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Flexible(
                          child: Text(
                            provider.defaultAddress!.recipientName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (provider.shippingFee != null)
                      Text(
                          "Shipping: ₦${NumberFormat('#,##0').format(provider.shippingFee)}",
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                  ] else
                    const Text("Add a shipping address",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProductDetail product) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, child) {
        return SliverAppBar(
          expandedHeight: 350.0,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 20),
                onPressed: () {
                  final url = '${AppConfig.baseUrl}/products/${product.slug}';
                  Share.share('Check out this product: $url');
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageCarousel(product.images, product.id),
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
              size: 60, color: Colors.grey[400]));
    }

    final validImages = images.where((img) => img.url.isNotEmpty).toList();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CarouselSlider(
          options: CarouselOptions(
              height: 400,
              viewportFraction: 1.0,
              enableInfiniteScroll: validImages.length > 1,
              onPageChanged: (index, reason) {
                setState(() => _currentImageIndex = index);
              }),
          items: validImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;
            Widget imageWidget = CachedNetworkImage(
                imageUrl: img.url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (c, u) => Container(color: Colors.grey[100]),
                errorWidget: (c, u, e) => const Icon(Icons.error));

            if (index == 0) {
              return Hero(tag: 'product_$productId', child: imageWidget);
            }
            return imageWidget;
          }).toList(),
        ),
        if (validImages.length > 1)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${_currentImageIndex + 1}/${validImages.length}",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSellerInfo(BuildContext context, ProductShop shop) {
    final hasLogo = shop.logoUrl != null && shop.logoUrl!.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundImage:
                  hasLogo ? CachedNetworkImageProvider(shop.logoUrl!) : null,
              backgroundColor: Colors.grey[100],
              child: !hasLogo
                  ? const Icon(Icons.storefront, size: 18, color: Colors.grey)
                  : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("95% Positive Feedback",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                minimumSize: const Size(0, 28),
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            child: const Text('Visit Store', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductDetail product) {
    if (product.reviews.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Reviews (${product.reviewsCount})",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          if (product.reviews.isNotEmpty) _buildReviewItem(product.reviews[0]),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(review.userName,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            _DetailsStarRating(rating: review.rating.toDouble(), size: 10),
          ],
        ),
        const SizedBox(height: 4),
        Text(review.comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.3)),
      ],
    );
  }

  Widget _buildRelatedProducts(List<HomeProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('You May Also Like',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Reduced height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              return Container(
                width: 140, // Smaller width
                margin: const EdgeInsets.only(right: 8),
                child: ModernProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 200, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(height: 20, width: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  Container(
                      height: 200, width: double.infinity, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
