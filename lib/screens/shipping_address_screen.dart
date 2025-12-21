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
      name: json['name'] ?? 'Home',
      recipientName: json['recipient_name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
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

  // Future implementation for delete:
  // Future<bool> deleteAddress(int id) async { ... }
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Addresses',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error loading addresses',
                    style: TextStyle(color: Colors.grey[600])));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final addresses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: addresses.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
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
            MaterialPageRoute(builder: (_) => const AddAddressScreen()),
          );
          if (addressAdded == true) {
            _loadAddresses();
          }
        },
        label: const Text('Add New'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  address.isDefault
                      ? Icons.check_circle
                      : Icons.location_on_outlined,
                  color: address.isDefault
                      ? AppTheme.primaryColor
                      : Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(address.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (address.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Default',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address.recipientName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(address.addressLine1,
                          style: TextStyle(color: Colors.grey[600])),
                      Text('${address.city}, ${address.state}',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(address.recipientPhone,
                          style:
                              TextStyle(color: Colors.grey[800], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to Edit (Needs Edit Screen)
                  },
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.grey),
                  label:
                      const Text("Edit", style: TextStyle(color: Colors.grey)),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[200]),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Logic to delete
                  },
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                  label: const Text("Delete",
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration:
                BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.map_outlined, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text('No Addresses Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Save your shipping details for faster checkout.',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
