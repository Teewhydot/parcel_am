import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/totp_settings_entity.dart';
import '../repositories/totp_repository.dart';

/// Use case for TOTP 2FA operations
class TotpUseCase {
  final TotpRepository _repository;

  TotpUseCase({TotpRepository? repository})
      : _repository = repository ?? GetIt.instance<TotpRepository>();

  /// Initialize 2FA setup - generates secret and QR code
  Future<Either<Failure, TotpSetupResult>> initializeSetup(
    String userId,
    String email,
  ) {
    return _repository.generateSecret(userId, email);
  }

  /// Complete 2FA setup by verifying the code from authenticator app
  Future<Either<Failure, bool>> completeSetup(String userId, String code) {
    return _repository.verifySetupCode(userId, code);
  }

  /// Verify a TOTP code for protected actions
  Future<Either<Failure, TotpVerificationResult>> verify(
    String userId,
    String code,
  ) {
    return _repository.verifyCode(userId, code);
  }

  /// Verify using a recovery code
  Future<Either<Failure, TotpVerificationResult>> verifyWithRecoveryCode(
    String userId,
    String code,
  ) {
    return _repository.verifyRecoveryCode(userId, code);
  }

  /// Get user's 2FA settings
  Future<Either<Failure, TotpSettingsEntity?>> getSettings(String userId) {
    return _repository.getSettings(userId);
  }

  /// Check if user has 2FA enabled
  Future<Either<Failure, bool>> is2FAEnabled(String userId) {
    return _repository.is2FAEnabled(userId);
  }

  /// Disable 2FA for user
  Future<Either<Failure, void>> disable2FA(String userId) {
    return _repository.disable2FA(userId);
  }

  /// Generate new recovery codes
  Future<Either<Failure, List<String>>> regenerateRecoveryCodes(String userId) {
    return _repository.regenerateRecoveryCodes(userId);
  }

  /// Get count of remaining recovery codes
  Future<Either<Failure, int>> getRemainingRecoveryCodesCount(String userId) {
    return _repository.getRemainingRecoveryCodesCount(userId);
  }

  /// Cancel setup in progress
  Future<Either<Failure, void>> cancelSetup(String userId) {
    return _repository.clearPendingSecret(userId);
  }
}
