import 'package:flutter/material.dart';
import 'package:kasuwa/providers/password_reset_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

// THE FIX: This screen no longer creates its own provider.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(PasswordResetProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final success = await provider.resetPassword(
        email: widget.email,
        otp: _otpController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Password has been reset successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate all the way back to the login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // It consumes the provider passed to it from the previous screen.
    return Consumer<PasswordResetProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Enter OTP'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'An OTP has been sent to ${widget.email}. Please enter it below to set a new password.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (provider.stage == PasswordResetStage.error)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(provider.message ?? 'An error occurred.',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                        labelText: '6-Digit OTP',
                        prefixIcon: Icon(Icons.vpn_key_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.length != 6)
                        ? 'Please enter a valid 6-digit OTP'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 8)
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_reset_outlined)),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _submitRequest(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : const Text('Reset Password',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
