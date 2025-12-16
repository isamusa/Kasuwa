import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/add_address_screen.dart';
import 'package:kasuwa/config/app_config.dart';

// --- Data Model ---
class Address {
  final int id;
  final String name;
  final String recipientName;
  final String recipientPhone;
  final String addressLine1;
  final String city;
  final String state;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.recipientName,
    required this.recipientPhone,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      recipientName: json['recipient_name'],
      recipientPhone: json['recipient_phone'],
      addressLine1: json['address_line_1'],
      city: json['city'],
      state: json['state'],
      isDefault: json['is_default'] == 1,
    );
  }
}

// --- Service ---
class ShippingAddressService {
  final AuthService _authService = AuthService();

  Future<List<Address>> getAddresses() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final url = Uri.parse('${AppConfig.apiBaseUrl}/shipping-addresses');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Address.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load addresses');
    }
  }
}

// --- UI ---
class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  _ShippingAddressScreenState createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  late Future<List<Address>> _addressesFuture;
  final ShippingAddressService _addressService = ShippingAddressService();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    setState(() {
      _addressesFuture = _addressService.getAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Shipping Addresses'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final addresses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              return _buildAddressCard(addresses[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? addressAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAddressScreen()),
          );
          // If an address was added, refresh the list
          if (addressAdded == true) {
            _loadAddresses();
          }
        },
        label: Text('Add New Address'),
        icon: Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: address.isDefault ? AppTheme.primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(address.name,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (address.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Default',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
            Divider(height: 24),
            Text(address.recipientName,
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text(address.recipientPhone),
            SizedBox(height: 4),
            Text(address.addressLine1),
            SizedBox(height: 4),
            Text('${address.city}, ${address.state}'),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: Text('Edit')),
                SizedBox(width: 8),
                TextButton(
                    onPressed: () {},
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No Addresses Found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Add your shipping address to make checkout faster.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
