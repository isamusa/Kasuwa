import 'package:flutter/material.dart';
import 'package:kasuwa/providers/password_reset_provider.dart';
import 'package:kasuwa/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/theme/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen now creates the unified provider that will be used by the next screen as well.
    return ChangeNotifierProvider(
      create: (_) => PasswordResetProvider(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  __ForgotPasswordViewState createState() => __ForgotPasswordViewState();
}

class __ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(
      BuildContext context, PasswordResetProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final success = await provider.sendOtp(_emailController.text);

      if (mounted && success) {
        // On success, navigate to the ResetPasswordScreen, passing the email and the provider.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider, // Pass the existing provider instance
              child: ResetPasswordScreen(email: _emailController.text),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PasswordResetProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your email address and we will send you a code to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                            ? 'Please enter a valid email'
                            : null,
                  ),
                  const SizedBox(height: 24),
                  if (provider.stage == PasswordResetStage.error)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(provider.message ?? 'An error occurred.',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _submitRequest(context, provider),
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
                        : const Text('Send Code',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
