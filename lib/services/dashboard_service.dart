import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/providers/dashboard_provider.dart';
import 'package:kasuwa/config/app_config.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    };

    try {
      // THE FIX: This service no longer fetches notifications.
      final responses = await Future.wait([
        http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/summary'),
            headers: headers),
        http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/my-products'),
            headers: headers),
        http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/sales-chart'),
            headers: headers),
      ]);

      if (responses.any((res) => res.statusCode != 200)) {
        throw Exception('Failed to load one or more dashboard endpoints');
      }

      final summary = DashboardSummary.fromJson(json.decode(responses[0].body));

      final productData = json.decode(responses[1].body);
      final products = (productData['data'] as List)
          .map((data) => SellerProduct.fromJson(data))
          .toList();

      final salesChartRawData =
          json.decode(responses[2].body)['sales_data'] as List;
      final salesData = salesChartRawData.asMap().entries.map((entry) {
        final value = double.tryParse(entry.value.toString()) ?? 0.0;
        return FlSpot(entry.key.toDouble(), value);
      }).toList();

      return {'summary': summary, 'products': products, 'salesData': salesData};
    } catch (e) {
      print("Dashboard Service Error: $e");
      throw Exception('An error occurred while fetching dashboard data.');
    }
  }
}
