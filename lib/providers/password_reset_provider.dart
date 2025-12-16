import 'package:flutter/material.dart';
import 'package:kasuwa/services/auth_service.dart';

// An enum to represent the different stages of the password reset flow.
enum PasswordResetStage {
  requestingOtp, // The user is on the first screen, entering their email.
  otpSent, // The OTP has been successfully sent.
  submitting, // A network request is in progress.
  success, // The password has been successfully reset.
  error, // An error has occurred.
}

class PasswordResetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  PasswordResetStage _stage = PasswordResetStage.requestingOtp;
  String? _message; // Can be used for both success and error messages.

  // Public Getters
  PasswordResetStage get stage => _stage;
  String? get message => _message;
  bool get isLoading => _stage == PasswordResetStage.submitting;

  /// Sends a request to the backend to dispatch a password reset OTP.
  Future<bool> sendOtp(String email) async {
    _stage = PasswordResetStage.submitting;
    _message = null;
    notifyListeners();

    final result = await _authService.sendPasswordResetLink(email);

    if (result['success']) {
      _stage = PasswordResetStage.otpSent;
      print('$_message');
      _message = result['message'];

      notifyListeners();
      return true;
    } else {
      _stage = PasswordResetStage.error;
      _message = result['message'];

      notifyListeners();
      return false;
    }
  }

  /// Submits the new password and OTP to the backend.
  Future<bool> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String otp,
  }) async {
    _stage = PasswordResetStage.submitting;
    _message = null;
    notifyListeners();

    final result = await _authService.resetPasswordWithOtp(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      otp: otp,
    );

    if (result['success']) {
      _stage = PasswordResetStage.success;
      _message = result['message'];
      print(_message);
      notifyListeners();
      return true;
    } else {
      _stage = PasswordResetStage.error;
      _message = result['message'];
      notifyListeners();
      return false;
    }
  }
}
