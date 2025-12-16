import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/user_provider.dart'; // Import your UserProvider
import '../services/api_service.dart'; // Import your ApiService

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true; // Store notification state
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.lock, color: Colors.grey),
            onTap: () {
              Navigator.pushNamed(context, '/change_password');
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationEnabled = value;
                  // Here you would typically send an API request to update
                  // notification preferences on the server.
                  // Example: _apiService.updateNotificationSettings(value);
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Log Out'),
            trailing: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () async {
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _apiService.logout();
      Provider.of<UserProvider>(context, listen: false).logout();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }
}
