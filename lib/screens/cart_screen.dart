import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:kasuwa/screens/checkout_screen.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Local state to track selected item IDs
  final Set<int> _selectedItemIds = {};
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Auto-select all items when cart opens (optional, standard e-com behavior)
      final cart = Provider.of<CartProvider>(context, listen: false);
      // We wait for frame to avoid setstate during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedItemIds.addAll(cart.items.map((e) => e.id));
        });
      });
      _isInit = false;
    }
  }

  void _toggleItem(int id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _toggleAll(List<CartItem> items) {
    setState(() {
      if (_selectedItemIds.length == items.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds.addAll(items.map((e) => e.id));
      }
    });
  }

  void _deleteItem(BuildContext context, int id) async {
    // 1. Optimistic UI update or Show Loading
    // Ideally, we show a dialog or loading indicator
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Item?"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Remove from selection first to prevent calculation errors
      setState(() {
        _selectedItemIds.remove(id);
      });

      // Call provider
      await Provider.of<CartProvider>(context, listen: false)
          .removeCartItem(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Item removed"),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle Android Back Button to go Home
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
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const EnhancedHomeScreen()),
              (route) => false,
            ),
          ),
          title: const Text("My Cart",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _toggleAll(cart.items),
                  child: Text(
                    _selectedItemIds.length == cart.items.length
                        ? "Deselect All"
                        : "Select All",
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (cart.items.isEmpty) {
              return _buildEmptyState(context);
            }

            // Calculate Totals based on Selection
            final selectedItems = cart.items
                .where((item) => _selectedItemIds.contains(item.id))
                .toList();

            final double selectionTotal = selectedItems.fold(
                0, (sum, item) => sum + (item.price * item.quantity));

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await cart.fetchCart();
                      // Re-sync selection if needed, or keep existing
                    },
                    color: AppTheme.primaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      itemCount: cart.items.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (ctx, i) {
                        final item = cart.items[i];
                        return _CartItemCard(
                          item: item,
                          isSelected: _selectedItemIds.contains(item.id),
                          onToggle: () => _toggleItem(item.id),
                          onDelete: () => _deleteItem(context, item.id),
                        );
                      },
                    ),
                  ),
                ),
                _buildCheckoutSection(context, selectedItems, selectionTotal),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined,
                  size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Cart is Empty",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Looks like you haven't added anything to your cart yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const EnhancedHomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Start Shopping",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
      BuildContext context, List<CartItem> selectedItems, double total) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    // Bottom padding for safe area (iPhone home bar / Android nav bar)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total (${selectedItems.length} items)",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text(
                currencyFormatter.format(total),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedItems.isEmpty
                  ? null
                  : () {
                      // Pass ONLY selected items to checkout
                      // We need to convert CartItems to CheckoutCartItems if necessary
                      // Assuming CheckoutScreen takes a list of items similar to CartItem

                      // NOTE: If CheckoutScreen expects a different model, map it here.
                      // For now, assuming CheckoutScreen accepts List<CartItem> or similar.
                      // If it needs `CheckoutCartItem`, you map it like this:

                      final checkoutItems = selectedItems
                          .map((item) => CheckoutCartItem(
                                productId: item.productId,
                                name: item.productName,
                                price: item.price,
                                quantity: item.quantity,
                                imageUrl: item.productImage ?? '',
                                variantDescription: item.variantDescription,
                              ))
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CheckoutScreen(itemsToCheckout: checkoutItems),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: selectedItems.isEmpty ? 0 : 4,
              ),
              child: Text(
                selectedItems.isEmpty ? "Select Items to Checkout" : "Checkout",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectedItems.isEmpty ? Colors.grey : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Checkbox
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: isSelected,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => onToggle(),
            ),
          ),

          // 2. Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.productImage ?? '',
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                      ),
                    )
                  ],
                ),
                if (item.variantDescription != null)
                  Text(
                    item.variantDescription!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormatter.format(item.price),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    // Quantity Controls
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _QuantityButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (item.quantity > 1) {
                                  cart.updateCartItemQuantity(
                                      item.id, item.quantity - 1);
                                }
                              }),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('${item.quantity}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          _QuantityButton(
                              icon: Icons.add,
                              onTap: () {
                                cart.updateCartItemQuantity(
                                    item.id, item.quantity + 1);
                              }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }
}
