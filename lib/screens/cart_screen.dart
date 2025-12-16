import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasuwa/screens/checkout_screen.dart'; // THE FIX: Import the checkout screen to access CheckoutCartItem
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kasuwa/theme/app_theme.dart';

// --- UI ---
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // The CartProvider is reactive and will fetch the cart automatically
    // when the user is authenticated. We can add an explicit refresh here
    // to ensure the data is fresh every time the screen is viewed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The entire screen is now driven by the CartProvider state.
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
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
                MaterialPageRoute(
                    builder: (context) => const EnhancedHomeScreen()),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'My Cart (${cart.itemCount})',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              actions: [
                if (cart.items.isNotEmpty)
                  Row(
                    children: [
                      Text("Select All", style: TextStyle(color: Colors.white)),
                      Checkbox(
                        value: cart.areAllItemsSelected,
                        onChanged: (selected) =>
                            cart.toggleSelectAll(selected ?? false),
                        checkColor: AppTheme.primaryColor,
                        activeColor: Colors.white,
                        side: BorderSide(color: Colors.white),
                      ),
                    ],
                  )
              ],
            ),
            body: _buildBody(cart),
            bottomSheet:
                cart.items.isNotEmpty ? _buildCheckoutBottomSheet(cart) : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(CartProvider cart) {
    if (cart.isLoading && cart.items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (cart.error != null) {
      return Center(child: Text('Error: ${cart.error}'));
    }
    if (cart.items.isEmpty) {
      return _buildEmptyCart();
    }
    return _buildCartList(cart);
  }

  Widget _buildCartList(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 120), // Padding for bottom sheet
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _buildCartItemCard(item, cart);
      },
    );
  }

  Widget _buildCartItemCard(CartItem item, CartProvider cart) {
    final isSelected = cart.selectedItemIds.contains(item.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? selected) =>
                      cart.toggleItemSelected(item.id),
                  activeColor: AppTheme.primaryColor,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (c, e, s) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(locale: 'en_NG', symbol: '₦')
                            .format(item.price),
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => cart.removeItem(item.id),
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  label: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
                _buildQuantityControl(item, cart),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, CartProvider cart) {
    final isUpdating = cart.updatingItemId == item.id;
    return Row(
      children: [
        _quantityButton(
            icon: Icons.remove,
            onPressed: isUpdating
                ? null
                : () => cart.updateQuantity(item.id, item.quantity - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isUpdating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(item.quantity.toString(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _quantityButton(
            icon: Icons.add,
            onPressed: isUpdating
                ? null
                : () => cart.updateQuantity(item.id, item.quantity + 1)),
      ],
    );
  }

  Widget _quantityButton(
      {required IconData icon, required VoidCallback? onPressed}) {
    return Material(
      color: onPressed == null ? Colors.grey[300] : Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 20, color: AppTheme.textColorPrimary),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Your Cart is Empty',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Looks like you haven\'t added anything to your cart yet.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Go back
            child:
                Text('Start Shopping', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomSheet(CartProvider cart) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦');
    final isCheckoutDisabled = cart.selectedItemIds.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2))
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total (${cart.selectedItemIds.length} items)',
                  style: TextStyle(color: Colors.grey[700])),
              Text(
                currencyFormatter.format(cart.selectedItemsTotalPrice),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: isCheckoutDisabled
                ? null
                : () {
                    final List<CheckoutCartItem> selectedItemsToCheckout =
                        cart.selectedItems
                            .map((item) => CheckoutCartItem(
                                  productId: item.productId,
                                  imageUrl: item.imageUrl,
                                  name: item.productName,
                                  price: item.price,
                                  quantity: item.quantity,
                                  variantDescription: item.variantDescription,
                                ))
                            .toList();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                                itemsToCheckout: selectedItemsToCheckout)));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Checkout',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
