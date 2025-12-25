import 'package:flutter/material.dart';
import 'package:kasuwa/services/auth_service.dart';

// An enum to represent the different stages of the password reset flow.
enum PasswordResetStage {
  requestingOtp, // The user is on the first screen, entering their email.
  otpSent, // The OTP has been successfully sent.
  submitting, // A network request is in progress (Loading state).
  success, // The password has been successfully reset.
  error, // An error has occurred.
}

class PasswordResetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  PasswordResetStage _stage = PasswordResetStage.requestingOtp;
  String? _message;

  // Public Getters
  PasswordResetStage get stage => _stage;
  String? get message => _message;

  // IsLoading is true whenever the stage is 'submitting'
  bool get isLoading => _stage == PasswordResetStage.submitting;

  /// 1. Request OTP (Sends email)
  Future<bool> sendOtp(String email) async {
    _stage = PasswordResetStage.submitting;
    _message = null;
    notifyListeners();

    try {
      final result = await _authService.sendPasswordResetLink(email);

      if (result['success']) {
        _stage = PasswordResetStage.otpSent;
        _message = result['message'];
        notifyListeners();
        return true;
      } else {
        _stage = PasswordResetStage.error;
        _message = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _stage = PasswordResetStage.error;
      _message = "Connection error. Please try again.";
      notifyListeners();
      return false;
    }
  }

  /// 2. Verify OTP (Real API Check)
  Future<bool> verifyOtp(String email, String otp) async {
    _stage = PasswordResetStage.submitting;
    notifyListeners();

    try {
      // Call the actual service method to verify the code
      final result = await _authService.verifyOtp(email, otp);

      if (result['success']) {
        // We revert stage to otpSent (or similar) just to stop the spinner.
        // The UI uses the return value 'true' to advance to the Password Screen.
        _stage = PasswordResetStage.otpSent;
        notifyListeners();
        return true;
      } else {
        _stage = PasswordResetStage.error;
        _message = result['message'] ?? "Invalid OTP code.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _stage = PasswordResetStage.error;
      _message = "Unable to verify OTP. Check your internet.";
      notifyListeners();
      return false;
    }
  }

  /// 3. Resend OTP
  Future<bool> resendOtp(String email) async {
    return await sendOtp(email);
  }

  /// 4. Final Reset (Submit New Password)
  Future<bool> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String otp,
  }) async {
    _stage = PasswordResetStage.submitting;
    _message = null;
    notifyListeners();

    try {
      final result = await _authService.resetPasswordWithOtp(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        otp: otp,
      );

      if (result['success']) {
        _stage = PasswordResetStage.success;
        _message = result['message'];
        notifyListeners();
        return true;
      } else {
        _stage = PasswordResetStage.error;
        _message = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _stage = PasswordResetStage.error;
      _message = "Failed to reset password. Please try again.";
      notifyListeners();
      return false;
    }
  }
}
