import 'package:equatable/equatable.dart';
import '../../domain/entities/totp_settings_entity.dart';
import '../../domain/repositories/totp_repository.dart';

/// Data class holding TOTP 2FA-related state
class TotpData extends Equatable {
  /// Current 2FA settings for the user
  final TotpSettingsEntity? settings;

  /// Whether 2FA is enabled for the user
  final bool isEnabled;

  /// Setup result during 2FA initialization (QR code, secret, recovery codes)
  final TotpSetupResult? setupResult;

  /// Whether we're currently in setup mode
  final bool isInSetupMode;

  /// Number of remaining unused recovery codes
  final int remainingRecoveryCodes;

  /// User input verification code
  final String verificationCode;

  /// Whether to display recovery codes (one-time display)
  final bool showRecoveryCodes;

  /// Whether verification was successful (for protected actions)
  final bool? verificationSuccess;

  /// Error message if any
  final String? errorMessage;

  const TotpData({
    this.settings,
    this.isEnabled = false,
    this.setupResult,
    this.isInSetupMode = false,
    this.remainingRecoveryCodes = 0,
    this.verificationCode = '',
    this.showRecoveryCodes = false,
    this.verificationSuccess,
    this.errorMessage,
  });

  TotpData copyWith({
    TotpSettingsEntity? settings,
    bool? isEnabled,
    TotpSetupResult? setupResult,
    bool? isInSetupMode,
    int? remainingRecoveryCodes,
    String? verificationCode,
    bool? showRecoveryCodes,
    bool? verificationSuccess,
    String? errorMessage,
  }) {
    return TotpData(
      settings: settings ?? this.settings,
      isEnabled: isEnabled ?? this.isEnabled,
      setupResult: setupResult ?? this.setupResult,
      isInSetupMode: isInSetupMode ?? this.isInSetupMode,
      remainingRecoveryCodes:
          remainingRecoveryCodes ?? this.remainingRecoveryCodes,
      verificationCode: verificationCode ?? this.verificationCode,
      showRecoveryCodes: showRecoveryCodes ?? this.showRecoveryCodes,
      verificationSuccess: verificationSuccess ?? this.verificationSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Clear setup-related data
  TotpData clearSetup() {
    return TotpData(
      settings: settings,
      isEnabled: isEnabled,
      setupResult: null,
      isInSetupMode: false,
      remainingRecoveryCodes: remainingRecoveryCodes,
      verificationCode: '',
      showRecoveryCodes: false,
      verificationSuccess: null,
      errorMessage: null,
    );
  }

  /// Clear verification-related data
  TotpData clearVerification() {
    return copyWith(
      verificationCode: '',
      verificationSuccess: null,
      errorMessage: null,
    );
  }

  /// Check if verification code is valid (6 digits)
  bool get isVerificationCodeValid {
    return verificationCode.length == 6 &&
        RegExp(r'^\d{6}$').hasMatch(verificationCode);
  }

  /// Check if we have recovery codes to display
  bool get hasRecoveryCodesToShow {
    return showRecoveryCodes &&
        setupResult != null &&
        setupResult!.recoveryCodes.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        settings,
        isEnabled,
        setupResult,
        isInSetupMode,
        remainingRecoveryCodes,
        verificationCode,
        showRecoveryCodes,
        verificationSuccess,
        errorMessage,
      ];
}
