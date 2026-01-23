import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Service for detecting and launching authenticator apps
class AuthenticatorAppLauncher {
  /// Singleton instance
  static final AuthenticatorAppLauncher _instance =
      AuthenticatorAppLauncher._internal();

  factory AuthenticatorAppLauncher() => _instance;

  AuthenticatorAppLauncher._internal();

  /// Check if any authenticator app can handle otpauth:// URIs
  Future<bool> canLaunchAuthenticatorApp(String otpauthUri) async {
    try {
      final uri = Uri.parse(otpauthUri);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Launch authenticator app with the given otpauth:// URI
  ///
  /// Returns true if launch was successful, false otherwise
  Future<bool> launchAuthenticatorApp(String otpauthUri) async {
    try {
      final uri = Uri.parse(otpauthUri);

      // Check if we can launch first
      if (!await canLaunchUrl(uri)) {
        return false;
      }

      // Launch with external application mode to open in the authenticator app
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly message when no authenticator app is installed
  String getNoAppInstalledMessage() {
    if (Platform.isIOS) {
      return 'No authenticator app found. Please scan the QR code manually or download an app like Google Authenticator or Authy from the App Store.';
    } else if (Platform.isAndroid) {
      return 'No authenticator app found. Please scan the QR code manually or download an app like Google Authenticator or Authy from the Play Store.';
    }
    return 'No authenticator app found. Please scan the QR code manually.';
  }

  /// Get a short message for snackbar display
  String getNoAppInstalledShortMessage() {
    return 'No authenticator app found. Please scan the QR code manually.';
  }
}
