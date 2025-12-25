import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasuwa/providers/password_reset_provider.dart';
import 'package:provider/provider.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;
  bool _isOtpVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Actions

  Future<void> _verifyOtp(PasswordResetProvider provider) async {
    if (_otpController.text.length != 6) {
      _showMessage('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    // Hide keyboard immediately so user sees the loading/success state clearly
    FocusManager.instance.primaryFocus?.unfocus();

    final success = await provider.verifyOtp(widget.email, _otpController.text);

    if (mounted) {
      if (success) {
        _showMessage('OTP verified successfully!', isError: false);
        // Small delay to let the user read the success message before switching
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _isOtpVerified = true);
          _timer?.cancel();
        }
      } else {
        // Explicit error message
        _showMessage(provider.message ?? 'Invalid OTP code', isError: true);
      }
    }
  }

  Future<void> _resendCode(PasswordResetProvider provider) async {
    if (!_canResend) return;
    final success = await provider.resendOtp(widget.email);
    if (mounted && success) {
      _showMessage('OTP sent successfully!', isError: false);
      startTimer();
    }
  }

  Future<void> _submitNewPassword(PasswordResetProvider provider) async {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final success = await provider.resetPassword(
        email: widget.email,
        otp: _otpController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted && success) {
        _showMessage('Password reset successfully! Please log in.',
            isError: false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        _showMessage(provider.message ?? 'Failed to reset password',
            isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Clear previous
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // UI Components

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PasswordResetProvider>(context);

    // LayoutBuilder gives us the full height of the screen
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Identify this scroll view for keyboard handling
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              // Ensure the container is at least as tall as the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _isOtpVerified
                          ? _buildPasswordResetStep(provider)
                          : _buildOtpStep(provider),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpStep(PasswordResetProvider provider) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildHeaderIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 30),
        const Text(
          "Verify It's You",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          "We've sent a 6-digit code to\n${widget.email}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 40),

        // OTP Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: _inputDecoration("Enter OTP").copyWith(
            counterText: "",
            hintText: "000000",
            hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        const SizedBox(height: 30),

        // Use Spacer to push buttons to the bottom, but IntrinsicHeight ensures
        // it doesn't break scrolling when keyboard is up.
        const Expanded(child: SizedBox(height: 20)),

        _buildPrimaryButton(
          text: "Verify Code",
          isLoading: provider.isLoading,
          onPressed: () => _verifyOtp(provider),
        ),

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _canResend ? () => _resendCode(provider) : null,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  const TextSpan(text: "Didn't receive code? "),
                  TextSpan(
                    text: _canResend ? "Resend" : "Wait ${_start}s",
                    style: TextStyle(
                      color: _canResend ? AppTheme.primaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20), // Bottom padding
      ],
    );
  }

  Widget _buildPasswordResetStep(PasswordResetProvider provider) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildHeaderIcon(Icons.lock_reset_rounded),
        const SizedBox(height: 30),
        const Text(
          "Create New Password",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          "Your new password must be different\nfrom previously used passwords.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 40),

        // Password Fields
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration("New Password").copyWith(
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) => (value == null || value.length < 8)
              ? 'Min 8 characters required'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: _inputDecoration("Confirm Password").copyWith(
            prefixIcon:
                const Icon(Icons.check_circle_outline, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (val) =>
              val != _passwordController.text ? 'Passwords do not match' : null,
        ),

        const SizedBox(height: 30),

        // Spacer pushes content down, IntrinsicHeight allows it to shrink on keyboard open
        const Expanded(child: SizedBox(height: 20)),

        _buildPrimaryButton(
          text: "Reset Password",
          isLoading: provider.isLoading,
          onPressed: () => _submitNewPassword(provider),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // Helpers

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      height: 80,
      width: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppTheme.primaryColor),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildPrimaryButton(
      {required String text,
      required VoidCallback onPressed,
      required bool isLoading}) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(text,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
