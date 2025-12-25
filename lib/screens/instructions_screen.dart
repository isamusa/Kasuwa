import 'package:flutter/material.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/seller_dashboard_screen.dart';
import 'package:kasuwa/services/shop_service.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

class InstructionsScreen extends StatefulWidget {
  final Map<String, String> shopData;

  const InstructionsScreen({super.key, required this.shopData});

  @override
  _InstructionsScreenState createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final ShopService _shopService = ShopService();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  Future<void> _submitCreateShop() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You must agree to the terms and conditions to proceed.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _shopService.createShop(
      name: widget.shopData['name']!,
      description: widget.shopData['description']!,
      location: widget.shopData['location']!,
      phoneNumber: widget.shopData['phone_number']!,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUserToSeller(result['data']['shop']);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Congratulations! Your shop is now live.'),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
        (route) => false,
      );
    } else {
      final errorMessage = result['message'] ?? 'An unknown error occurred.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $errorMessage'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Onboarding (Step 2 of 2)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInstructionItem('1', 'Shop Verification & Uploads',
                'After creating your shop, you cannot start uploading products immediately. The Kasuwa team will reach out to verify your shop details first. Once verified, you can start listing your items.'),
            _buildInstructionItem('2', 'Immediate Payment',
                'Good news! You will be paid as soon as the user successfully pays for the product. No long waiting periods.'),
            _buildInstructionItem('3', 'Return Policy & Refunds',
                'Users have a 12-hour window from delivery to initiate a return. If a return request is verified and valid, the user will be refunded, and the item will be returned to your shop.'),
            _buildInstructionItem('4', 'Notification of Sale',
                'If a user selects an item in your shop and pays for it, you will be notified immediately.'),
            _buildInstructionItem('5', 'Item Pickup',
                'A Kasuwa admin or agent will contact you to arrange pickup of the item for delivery to the customer.'),
            _buildInstructionItem('6', 'Service Charge',
                'Kasuwa will charge a 5% commission on the total value of every successful transaction.'),
            const SizedBox(height: 32),
            _buildTermsCheckbox(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  (_isLoading || !_agreedToTerms) ? null : _submitCreateShop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Agree & Create My Shop',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.info_outline, size: 60, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text(
          'How Selling Works',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please read and agree to the following terms before creating your shop.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(
      String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor,
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(color: Colors.grey[800], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        const Expanded(
          child: Text(
            'I have read, understood, and agree to the terms and conditions.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
