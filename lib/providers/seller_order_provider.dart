import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasuwa/config/app_config.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/models/seller_order_model.dart';

class SellerOrderProvider with ChangeNotifier {
  final AuthProvider _auth;
  List<SellerOrder> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all';

  SellerOrderProvider(this._auth);

  List<SellerOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  Future<void> fetchOrders({String status = 'all'}) async {
    _currentFilter = status;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.token;
      if (token == null) throw Exception("Not authenticated");

      // Ensure API URL is correct
      final url =
          Uri.parse('${AppConfig.apiBaseUrl}/shop/orders?status=$status');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      print("Seller Orders Status: ${response.statusCode}"); // DEBUG

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle pagination 'data' key or direct list
        final List<dynamic> ordersList =
            (data['data'] != null) ? data['data'] : data;

        print("Orders found: ${ordersList.length}"); // DEBUG

        _orders = ordersList.map((json) => SellerOrder.fromJson(json)).toList();
      } else {
        print("Seller Orders Error: ${response.body}"); // DEBUG
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print("Seller Order Exception: $e"); // DEBUG
      print(stackTrace); // DEBUG
      _error = "Could not load orders.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int orderId, String newStatus) async {
    try {
      final token = _auth.token;
      final url =
          Uri.parse('${AppConfig.apiBaseUrl}/shop/orders/$orderId/status');

      final response = await http.put(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'status': newStatus}));

      if (response.statusCode == 200) {
        // Refresh the list to reflect changes
        await fetchOrders(status: _currentFilter);
        return true;
      }
      return false;
    } catch (e) {
      print("Update Status Error: $e");
      return false;
    }
  }
}
