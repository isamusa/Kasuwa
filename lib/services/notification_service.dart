import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasuwa/config/app_config.dart';

class NotificationService {
  Future<List<dynamic>> getNotifications(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/notifications');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      log(response.body);
      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load notifications with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Notification Service Error: $e');
      throw Exception('Could not fetch notifications.');
    }
  }

  Future<bool> markAsRead(String notificationId, String token) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$notificationId/read');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/notifications/read-all');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
