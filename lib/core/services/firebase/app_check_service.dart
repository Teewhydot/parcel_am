import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  static AppCheckService? _instance;
  static AppCheckService get instance => _instance ??= AppCheckService();

  AppCheckService();

  Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        // For Android debug builds
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        // For iOS debug builds (when iOS support is added)
        appleProvider: kDebugMode 
            ? AppleProvider.debug 
            : AppleProvider.appAttest,
      );
      
      debugPrint('Firebase App Check initialized successfully');
      
      // Get token to verify setup
      if (kDebugMode) {
        final token = await FirebaseAppCheck.instance.getToken();
        debugPrint('App Check Token: ${token?.substring(0, 20)}...');
      }
      
    } catch (e) {
      debugPrint('Firebase App Check initialization error: $e');
      // Don't throw error - App Check is optional for development
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      debugPrint('Failed to get App Check token: $e');
      return null;
    }
  }

  void onTokenChanged(void Function(String?) callback) {
    FirebaseAppCheck.instance.onTokenChange.listen(callback);
  }

  // For production setup instructions
  static const String productionSetupInstructions = '''
# Production App Check Setup

## 1. Play Integrity Setup (Android)
1. Go to Google Play Console
2. Enable Play Integrity API for your app
3. In Firebase Console → Project Settings → App Check
4. Enable Play Integrity provider for your Android app

## 2. App Attest Setup (iOS) - Future
1. Enable App Attest in Xcode project capabilities
2. In Firebase Console → Project Settings → App Check  
3. Enable App Attest provider for your iOS app

## 3. Testing with Debug Tokens
For testing on development devices:
1. In Firebase Console → Project Settings → App Check
2. Add debug tokens for test devices
3. Register SHA-1 of debug keystore

## 4. Monitoring
Monitor App Check usage in Firebase Console:
- Valid vs Invalid requests
- Token refresh rates
- Provider success rates
''';
}