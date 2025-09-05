import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Test phone numbers for Firebase Auth (Nigerian format)
  static const Map<String, String> testPhoneNumbers = {
    '+2341234567890': '123456',
    '+2341234567891': '123456', 
    '+2341234567892': '123456',
    '+2341234567893': '123456',
    '+2341234567894': '123456',
  };

  // Standard OTP code for all test numbers
  static const String testOtpCode = '123456';

  // Firebase App Check configuration
  static const Map<String, dynamic> appCheckConfig = {
    'debug_token_enabled': kDebugMode,
    'production_provider': 'playIntegrity', // For production builds
    'development_provider': 'debug', // For debug builds
  };

  // Phone authentication settings
  static const Map<String, dynamic> phoneAuthConfig = {
    'timeout_duration': 60, // seconds
    'resend_delay': 60, // seconds  
    'max_attempts': 5,
    'supported_country_codes': ['+234'], // Nigeria only for now
    'default_country_code': '+234',
    'auto_retrieve_timeout': 0, // Instant auto-retrieval on Android
    'force_resending_token': null,
  };

  // Regional settings for Nigeria
  static const Map<String, dynamic> nigeriaConfig = {
    'country_code': '+234',
    'country_name': 'Nigeria',
    'flag_emoji': '🇳🇬',
    'phone_length': 10, // digits after country code
    'valid_prefixes': ['701', '703', '704', '705', '706', '708', '801', '802', '803', '804', '805', '806', '807', '808', '809', '810', '811', '812', '813', '814', '815', '816', '817', '818', '819', '901', '902', '903', '904', '905', '906', '907', '908', '909', '915', '916', '917', '918'],
  };

  // App-wide Firebase settings
  static const Map<String, dynamic> firebaseSettings = {
    'app_verification_disabled_for_testing': kDebugMode,
    'language_code': 'en',
    'force_recaptcha_flow_for_testing': false,
    'custom_auth_domain': null, // Use default
  };

  // Error messages for Nigerian users
  static const Map<String, String> errorMessages = {
    'invalid_phone_number': 'Please enter a valid Nigerian phone number',
    'invalid_verification_code': 'The verification code is incorrect',
    'session_expired': 'Verification session has expired. Please try again',
    'too_many_requests': 'Too many requests. Please wait before trying again',
    'network_error': 'Please check your internet connection',
    'unknown_error': 'Something went wrong. Please try again',
    'phone_number_already_exists': 'This phone number is already registered',
  };

  // Success messages
  static const Map<String, String> successMessages = {
    'code_sent': 'Verification code sent successfully',
    'phone_verified': 'Phone number verified successfully',
    'login_success': 'Login successful',
    'registration_success': 'Registration successful',
  };

  // UI configuration
  static const Map<String, dynamic> uiConfig = {
    'phone_input_mask': '+234 ### ### ####',
    'otp_length': 6,
    'show_country_flag': true,
    'auto_focus_otp': true,
    'vibrate_on_error': true,
    'show_resend_timer': true,
  };

  // Get test phone numbers based on environment
  static Map<String, String> getTestPhoneNumbers() {
    return kDebugMode ? testPhoneNumbers : {};
  }

  // Check if phone number is a test number
  static bool isTestPhoneNumber(String phoneNumber) {
    if (!kDebugMode) return false;
    return testPhoneNumbers.containsKey(phoneNumber);
  }

  // Get OTP for test phone number
  static String? getTestOtp(String phoneNumber) {
    if (!kDebugMode) return null;
    return testPhoneNumbers[phoneNumber];
  }

  // Validate Nigerian phone number format
  static bool isValidNigerianNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it matches +234XXXXXXXXX pattern (13 characters total)
    if (!cleanNumber.startsWith('+234') || cleanNumber.length != 14) {
      return false;
    }
    
    // Extract the main number part (after +234)
    final mainNumber = cleanNumber.substring(4);
    
    // Check if it's exactly 10 digits and starts with valid prefix
    if (mainNumber.length != 10) return false;
    
    final prefix = mainNumber.substring(0, 3);
    return nigeriaConfig['valid_prefixes'].contains(prefix);
  }

  // Format phone number for display
  static String formatPhoneNumberForDisplay(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.startsWith('+234') && cleanNumber.length == 14) {
      final mainPart = cleanNumber.substring(4);
      return '+234 ${mainPart.substring(0, 3)} ${mainPart.substring(3, 6)} ${mainPart.substring(6)}';
    }
    
    return phoneNumber;
  }

  // Get error message for error code
  static String getErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? errorMessages['unknown_error']!;
  }

  // Get success message for success type
  static String getSuccessMessage(String successType) {
    return successMessages[successType] ?? 'Operation completed successfully';
  }
}