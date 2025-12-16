import 'package:flutter/material.dart';
import 'package:kasuwa/screens/order_details_screen.dart';
import 'package:kasuwa/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

// --- UI ---
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data using the provider when the screen is first built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The screen now simply consumes the provider's state.
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'My Orders',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: _buildBody(context, orderProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OrderProvider orderProvider) {
    // Show a loading indicator only if the list is empty and we are fetching.
    if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    // Show an error only if there are no orders to display.
    if (orderProvider.error != null && orderProvider.orders.isEmpty) {
      return Center(child: Text('Error: ${orderProvider.error}'));
    }
    if (orderProvider.orders.isEmpty) {
      return _buildEmptyState();
    }

    final orders = orderProvider.orders;
    // The RefreshIndicator now calls the provider directly.
    return RefreshIndicator(
      onRefresh: () => orderProvider.fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(context, orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderSummary order) {
    final statusColor = _getStatusColor(order.status);

    final pStatusColor = _paymentStatusColor(order.payment);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      color: const Color.fromARGB(255, 238, 238, 238),
      shadowColor: const Color.fromARGB(97, 0, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(orderId: order.id)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(order.status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              Text(order.date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Divider(height: 24),
              Text('Items (${order.itemCount})',
                  style: TextStyle(color: Colors.grey[800])),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.items.map((e) => e.productName).join(', '),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(order.payment,
                        style: TextStyle(
                            color: pStatusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount',
                      style: TextStyle(color: Colors.grey[800])),
                  Text(order.totalAmount,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor)),
                ],
              ),
              Divider(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'shipped':
      case 'in transit':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _paymentStatusColor(String payment) {
    switch (payment.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending payment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No Orders Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Your past orders will appear here.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
