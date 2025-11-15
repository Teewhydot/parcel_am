import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // App-wide Firebase settings
  static const Map<String, dynamic> firebaseSettings = {
    'app_verification_disabled_for_testing': kDebugMode,
    'language_code': 'en',
    'force_recaptcha_flow_for_testing': false,
    'custom_auth_domain': null, // Use default
  };

  // Error messages
  static const Map<String, String> errorMessages = {
    'invalid_verification_code': 'The verification code is incorrect',
    'session_expired': 'Verification session has expired. Please try again',
    'too_many_requests': 'Too many requests. Please wait before trying again',
    'network_error': 'Please check your internet connection',
    'unknown_error': 'Something went wrong. Please try again',
  };

  // Success messages
  static const Map<String, String> successMessages = {
    'login_success': 'Login successful',
    'registration_success': 'Registration successful',
  };

  // Get error message for error code
  static String getErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? errorMessages['unknown_error']!;
  }

  // Get success message for success type
  static String getSuccessMessage(String successType) {
    return successMessages[successType] ?? 'Operation completed successfully';
  }
}