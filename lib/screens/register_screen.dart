import 'package:flutter/material.dart';
import 'package:kasuwa/services/auth_service.dart';
import 'package:kasuwa/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _agreedToTerms = false;

  void _register() async {
    FocusScope.of(context).unfocus();
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You must agree to the Terms & Conditions")));
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
        referralCode: _referralController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please login.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text("Create Account",
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text("Join Kasuwa to start shopping",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput(
                        "Full Name", Icons.person_outline, _nameController),
                    const SizedBox(height: 16),
                    _buildInput(
                        "Email Address", Icons.email_outlined, _emailController,
                        isEmail: true),
                    const SizedBox(height: 16),
                    _buildInput(
                        "Password", Icons.lock_outline, _passwordController,
                        isPass: true),
                    const SizedBox(height: 16),
                    _buildInput("Confirm Password", Icons.lock_outline,
                        _confirmController,
                        isPass: true),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referralController,
                      decoration: const InputDecoration(
                        labelText: "Referral Code (Optional)",
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _agreedToTerms = v!),
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        Text("I agree to the ",
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () {}, // Show terms modal
                          child: Text("Terms & Conditions",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up"),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Login"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, IconData icon, TextEditingController controller,
      {bool isPass = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass && _obscurePass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (v) {
        if (v == null || v.isEmpty) return "$label is required";
        if (isEmail && !v.contains('@')) return "Invalid email";
        if (isPass && v.length < 6) return "Min 6 chars";
        if (isPass &&
            label.contains("Confirm") &&
            v != _passwordController.text) return "Passwords don't match";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              )
            : null,
      ),
    );
  }
}
