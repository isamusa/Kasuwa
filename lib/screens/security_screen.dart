import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    // Call the provider logic
    final success = await authProvider.changePassword(
      _currentPassController.text,
      _newPassController.text,
    );

    if (!mounted) return;

    if (success) {
      // 1. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Clear fields
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();

      // 3. Unfocus keyboard
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      // 4. Show Error Message from Backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? "Failed to update password"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure? This action is permanent and cannot be undone. All your data will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // delete account logic not yet implemented
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deletion request sent.")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the provider
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Security",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Authentication Settings
            const Text("Authentication",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _biometricEnabled,
                    activeColor: AppTheme.primaryColor,
                    title: const Text("Biometric Login",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Use FaceID or Fingerprint to log in"),
                    onChanged: (val) => setState(() => _biometricEnabled = val),
                  ),
                  Divider(height: 1, color: Colors.grey[100]),
                  SwitchListTile(
                    value: _twoFactorEnabled,
                    activeColor: AppTheme.primaryColor,
                    title: const Text("Two-Factor Auth (2FA)",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Verify with OTP via email/SMS"),
                    onChanged: (val) => setState(() => _twoFactorEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section 2: Change Password
            const Text("Change Password",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPasswordField(
                      label: "Current Password",
                      controller: _currentPassController,
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      label: "New Password",
                      controller: _newPassController,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      label: "Confirm New Password",
                      controller: _confirmPassController,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (val) {
                        if (val != _newPassController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Button with Loading State
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleChangePassword(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor:
                              AppTheme.primaryColor.withOpacity(0.6),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text("Update Password",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Section 3: Danger Zone
            Center(
              child: TextButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text("Delete Account",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator:
          validator ?? (val) => val!.length < 6 ? "Minimum 6 characters" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
