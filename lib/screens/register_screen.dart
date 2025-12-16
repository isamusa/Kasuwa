import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false; // Add a loading state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        referralCode: _referralCodeController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.of(context).pop(); // Go back to login screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['message']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image and Gradient Overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/login_background.jpg'), // Reusing the same asset
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.85),
                  AppTheme.accentColor.withOpacity(0.85)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Registration Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildRegistrationForm(),
                    const SizedBox(height: 30),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join the largest marketplace in Jos!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name Field
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: AppTheme.textColorPrimary),
            decoration: _inputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 16),
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppTheme.textColorPrimary),
            decoration: _inputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your email';
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: AppTheme.textColorPrimary),
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textColorSecondary,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter a password';
              if (value.length < 8)
                return 'Password must be at least 8 characters long';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(color: AppTheme.textColorPrimary),
            decoration: _inputDecoration(
              hintText: 'Confirm your password',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textColorSecondary,
                ),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please confirm your password';
              if (value != _passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referralCodeController,
            decoration: const InputDecoration(
              labelText: 'Referral Code (Optional)',
              prefixIcon: Icon(Icons.card_giftcard_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),

          const SizedBox(height: 30),

          // Register Button
          ElevatedButton(
            onPressed: _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: Text(
              'CREATE ACCOUNT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ",
            style: TextStyle(color: Colors.white.withOpacity(0.9))),
        TextButton(
          onPressed: () {
            // Navigate back to LoginScreen
            Navigator.of(context).pop();
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppTheme.textColorSecondary),
      prefixIcon: Icon(prefixIcon, color: AppTheme.textColorSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
    );
  }
}
