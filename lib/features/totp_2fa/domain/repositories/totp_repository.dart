import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/totp_settings_entity.dart';

/// Result class for TOTP setup initialization
class TotpSetupResult {
  /// The TOTP secret formatted for display (with spaces for readability)
  final String secretForDisplay;

  /// The raw TOTP secret (for internal use)
  final String secret;

  /// The otpauth:// URI for QR code generation
  final String qrCodeUri;

  /// List of plain text recovery codes (shown to user only once)
  final List<String> recoveryCodes;

  const TotpSetupResult({
    required this.secretForDisplay,
    required this.secret,
    required this.qrCodeUri,
    required this.recoveryCodes,
  });
}

/// Result class for TOTP verification
class TotpVerificationResult {
  /// Whether the code was valid
  final bool isValid;

  /// Whether a recovery code was used (vs regular TOTP code)
  final bool isRecoveryCode;

  /// Remaining recovery codes count (if recovery code was used)
  final int? remainingRecoveryCodes;

  const TotpVerificationResult({
    required this.isValid,
    this.isRecoveryCode = false,
    this.remainingRecoveryCodes,
  });
}

/// Repository interface for TOTP 2FA operations
abstract class TotpRepository {
  /// Generate a new TOTP secret for the user
  /// Returns setup result with secret, QR code URI, and recovery codes
  Future<Either<Failure, TotpSetupResult>> generateSecret(
    String userId,
    String email,
  );

  /// Verify a TOTP code during setup and enable 2FA if valid
  Future<Either<Failure, bool>> verifySetupCode(String userId, String code);

  /// Verify a TOTP code for authentication/protected actions
  Future<Either<Failure, TotpVerificationResult>> verifyCode(
    String userId,
    String code,
  );

  /// Verify using a recovery code
  Future<Either<Failure, TotpVerificationResult>> verifyRecoveryCode(
    String userId,
    String code,
  );

  /// Get user's TOTP settings
  Future<Either<Failure, TotpSettingsEntity?>> getSettings(String userId);

  /// Check if user has 2FA enabled
  Future<Either<Failure, bool>> is2FAEnabled(String userId);

  /// Disable TOTP 2FA for user (requires verification first)
  Future<Either<Failure, void>> disable2FA(String userId);

  /// Generate new recovery codes (replaces existing ones)
  Future<Either<Failure, List<String>>> regenerateRecoveryCodes(String userId);

  /// Get count of remaining unused recovery codes
  Future<Either<Failure, int>> getRemainingRecoveryCodesCount(String userId);

  /// Store TOTP secret securely in local storage
  Future<Either<Failure, void>> storeSecret(String userId, String secret);

  /// Get stored TOTP secret from local storage
  Future<Either<Failure, String?>> getSecret(String userId);

  /// Clear stored TOTP secret from local storage
  Future<Either<Failure, void>> clearSecret(String userId);

  /// Store pending secret during setup (before verification)
  Future<Either<Failure, void>> storePendingSecret(
    String userId,
    String secret,
  );

  /// Get pending secret during setup
  Future<Either<Failure, String?>> getPendingSecret(String userId);

  /// Clear pending secret after setup completion or cancellation
  Future<Either<Failure, void>> clearPendingSecret(String userId);
}
