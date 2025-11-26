import 'package:flutter/material.dart';
import '../services/auth/kyc_guard.dart';

/// Defines the action to take when a KYC-protected button is pressed
/// but the user doesn't have KYC access.
enum KycBlockedAction {
  /// Shows a snackbar message informing the user about KYC requirement
  showSnackbar,

  /// Navigates the user to the KYC verification screen
  navigateToKyc,
}

/// Extension methods for [KycBlockedAction]
extension KycBlockedActionExtension on KycBlockedAction {
  /// Executes the appropriate action based on the enum value
  void execute(BuildContext context) {
    switch (this) {
      case KycBlockedAction.showSnackbar:
        KycGuard.instance.showKycBlockedSnackbar();
        break;
      case KycBlockedAction.navigateToKyc:
        // TODO: Navigate to KYC screen when available
        // For now, fall back to showing snackbar
        KycGuard.instance.showKycBlockedSnackbar();
        break;
    }
  }
}
