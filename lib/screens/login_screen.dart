import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart'; // Ensure this is in pubspec
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/screens/register_screen.dart';
import 'package:kasuwa/screens/forgot_password_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // ... (dispose and _submitLogin logic same as before, see snippet below for UI changes)

  // Copy previous logic for _submitLogin here...
  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
          _emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (result['success']) {
        if (widget.onLoginSuccess != null) widget.onLoginSuccess!();
        if (Navigator.canPop(context))
          Navigator.of(context).pop();
        else
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const EnhancedHomeScreen()));
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Header with Logo
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 10))
                        ]),
                    child: const Icon(Icons.shopping_bag,
                        size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Welcome Back!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text("Please sign in to your account",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 50),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v!.isEmpty || !v.contains('@'))
                            ? 'Invalid email'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (v) =>
                            v!.length < 6 ? 'Password too short' : null,
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),

                const SizedBox(height: 30),
                // Social Login Section
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Or login with",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {}, // Implement Google Sign In later
                        icon: Icon(MdiIcons.google, color: Colors.red),
                        label: const Text("Google",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {}, // Implement Facebook later
                        icon: Icon(MdiIcons.facebook, color: Colors.blue),
                        label: const Text("Facebook",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text("Register"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
