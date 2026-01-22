import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/totp_settings_entity.dart';
import '../../domain/repositories/totp_repository.dart';
import '../datasources/totp_local_data_source.dart';
import '../datasources/totp_remote_data_source.dart';
import '../models/totp_settings_model.dart';
import '../models/recovery_code_model.dart';

/// Implementation of TOTP repository
class TotpRepositoryImpl implements TotpRepository {
  final TotpLocalDataSource _localDataSource;
  final TotpRemoteDataSource _remoteDataSource;

  /// App name shown in authenticator apps
  static const String _issuer = 'ParcelAM';

  /// Number of recovery codes to generate
  static const int _recoveryCodeCount = 8;

  /// Length of each recovery code (in bytes, will be hex encoded)
  static const int _recoveryCodeLength = 8;

  /// TOTP configuration
  static const int _totpDigits = 6;
  static const int _totpInterval = 30;

  TotpRepositoryImpl({
    TotpLocalDataSource? localDataSource,
    TotpRemoteDataSource? remoteDataSource,
  })  : _localDataSource =
            localDataSource ?? GetIt.instance<TotpLocalDataSource>(),
        _remoteDataSource =
            remoteDataSource ?? GetIt.instance<TotpRemoteDataSource>();

  @override
  Future<Either<Failure, TotpSetupResult>> generateSecret(
    String userId,
    String email,
  ) async {
    try {
      // Generate cryptographically secure random secret (20 bytes = 160 bits)
      final secret = _generateRandomSecret();

      // Store pending secret locally
      await _localDataSource.storePendingSecret(userId, secret);

      // Generate QR code URI
      final qrCodeUri = _generateQrUri(email, secret);

      // Generate recovery codes
      final recoveryCodes = _generateRecoveryCodes();

      // Store pending recovery codes
      await _localDataSource.storePendingRecoveryCodes(userId, recoveryCodes);

      return Right(TotpSetupResult(
        secretForDisplay: _formatSecretForDisplay(secret),
        secret: secret,
        qrCodeUri: qrCodeUri,
        recoveryCodes: recoveryCodes,
      ));
    } catch (e) {
      return Left(TotpSetupFailure(failureMessage: 'Failed to generate 2FA secret: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifySetupCode(
    String userId,
    String code,
  ) async {
    try {
      // Get pending secret
      final pendingSecret = await _localDataSource.getPendingSecret(userId);
      if (pendingSecret == null) {
        return const Left(TotpSetupFailure(
          failureMessage: 'No pending 2FA setup found. Please start setup again.',
        ));
      }

      // Validate TOTP code
      if (!_validateTotp(pendingSecret, code)) {
        return const Left(TotpVerificationFailure(
          failureMessage: 'Invalid verification code. Please try again.',
        ));
      }

      // Get pending recovery codes
      final pendingRecoveryCodes =
          await _localDataSource.getPendingRecoveryCodes(userId);
      if (pendingRecoveryCodes == null || pendingRecoveryCodes.isEmpty) {
        return const Left(TotpSetupFailure(
          failureMessage: 'Recovery codes not found. Please restart setup.',
        ));
      }

      // Commit: store secret permanently
      await _localDataSource.storeSecret(userId, pendingSecret);
      await _localDataSource.clearPendingSecret(userId);

      // Create/update Firestore settings
      final settings = TotpSettingsModel(
        id: userId,
        userId: userId,
        isEnabled: true,
        enabledAt: DateTime.now(),
        lastVerifiedAt: DateTime.now(),
        failedAttempts: 0,
      );
      await _remoteDataSource.updateSettings(settings);

      // Store hashed recovery codes in Firestore
      final hashedCodes = pendingRecoveryCodes.map((code) {
        return RecoveryCodeModel(
          hash: _hashRecoveryCode(code),
          isUsed: false,
        );
      }).toList();
      await _remoteDataSource.storeRecoveryCodes(userId, hashedCodes);

      // Clear pending recovery codes
      await _localDataSource.clearPendingRecoveryCodes(userId);

      return const Right(true);
    } catch (e) {
      return Left(TotpSetupFailure(failureMessage: 'Failed to complete 2FA setup: $e'));
    }
  }

  @override
  Future<Either<Failure, TotpVerificationResult>> verifyCode(
    String userId,
    String code,
  ) async {
    try {
      // Check if user has 2FA enabled and not locked
      final settings = await _remoteDataSource.getSettings(userId);
      if (settings == null || !settings.isEnabled) {
        return const Left(TotpNotConfiguredFailure());
      }

      // Check if account is locked
      if (settings.isLocked) {
        return Left(TotpLockedFailure(
          failureMessage:
              'Too many failed attempts. Please try again in ${settings.remainingLockMinutes} minutes.',
          lockedUntil: settings.lockedUntil!,
        ));
      }

      // Get stored secret
      final secret = await _localDataSource.getSecret(userId);
      if (secret == null) {
        return const Left(TotpNotConfiguredFailure(
          failureMessage: '2FA secret not found on this device. Please disable and re-enable 2FA.',
        ));
      }

      // Validate TOTP code
      final isValid = _validateTotp(secret, code);

      if (isValid) {
        // Reset failed attempts on success
        await _remoteDataSource.resetFailedAttempts(userId);
        return const Right(TotpVerificationResult(
          isValid: true,
          isRecoveryCode: false,
        ));
      } else {
        // Increment failed attempts
        await _remoteDataSource.incrementFailedAttempts(
          userId,
          settings.failedAttempts,
        );
        return const Left(TotpVerificationFailure());
      }
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Verification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, TotpVerificationResult>> verifyRecoveryCode(
    String userId,
    String code,
  ) async {
    try {
      // Check if user has 2FA enabled
      final settings = await _remoteDataSource.getSettings(userId);
      if (settings == null || !settings.isEnabled) {
        return const Left(TotpNotConfiguredFailure());
      }

      // Get recovery codes
      final recoveryCodes = await _remoteDataSource.getRecoveryCodes(userId);
      if (recoveryCodes == null) {
        return const Left(RecoveryCodeFailure(
          failureMessage: 'No recovery codes found',
        ));
      }

      // Check if all codes are exhausted
      if (recoveryCodes.isExhausted) {
        return const Left(RecoveryCodeExhaustedFailure());
      }

      // Hash the input code and check against stored hashes
      final inputHash = _hashRecoveryCode(code.toUpperCase().replaceAll(' ', ''));

      final matchingCode = recoveryCodes.codes.where(
        (c) => c.hash == inputHash && !c.isUsed,
      );

      if (matchingCode.isEmpty) {
        // Increment failed attempts
        await _remoteDataSource.incrementFailedAttempts(
          userId,
          settings.failedAttempts,
        );
        return const Left(RecoveryCodeFailure(
          failureMessage: 'Invalid recovery code',
        ));
      }

      // Mark the code as used
      await _remoteDataSource.markRecoveryCodeUsed(userId, inputHash);

      // Reset failed attempts
      await _remoteDataSource.resetFailedAttempts(userId);

      // Get updated count
      final updatedCodes = await _remoteDataSource.getRecoveryCodes(userId);
      final remainingCount = updatedCodes?.remainingCount ?? 0;

      return Right(TotpVerificationResult(
        isValid: true,
        isRecoveryCode: true,
        remainingRecoveryCodes: remainingCount,
      ));
    } catch (e) {
      return Left(RecoveryCodeFailure(failureMessage: 'Recovery code verification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, TotpSettingsEntity?>> getSettings(String userId) async {
    try {
      final settings = await _remoteDataSource.getSettings(userId);
      return Right(settings?.toEntity());
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to get 2FA settings: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> is2FAEnabled(String userId) async {
    try {
      final settings = await _remoteDataSource.getSettings(userId);
      return Right(settings?.isEnabled ?? false);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> disable2FA(String userId) async {
    try {
      // Clear local secret
      await _localDataSource.clearSecret(userId);

      // Delete Firestore settings
      await _remoteDataSource.deleteSettings(userId);

      // Delete recovery codes
      await _remoteDataSource.deleteRecoveryCodes(userId);

      return const Right(null);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to disable 2FA: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> regenerateRecoveryCodes(
    String userId,
  ) async {
    try {
      // Check if 2FA is enabled
      final settings = await _remoteDataSource.getSettings(userId);
      if (settings == null || !settings.isEnabled) {
        return const Left(TotpNotConfiguredFailure());
      }

      // Generate new recovery codes
      final newCodes = _generateRecoveryCodes();

      // Store hashed codes in Firestore (replaces old ones)
      final hashedCodes = newCodes.map((code) {
        return RecoveryCodeModel(
          hash: _hashRecoveryCode(code),
          isUsed: false,
        );
      }).toList();
      await _remoteDataSource.storeRecoveryCodes(userId, hashedCodes);

      return Right(newCodes);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to regenerate recovery codes: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getRemainingRecoveryCodesCount(
    String userId,
  ) async {
    try {
      final codes = await _remoteDataSource.getRecoveryCodes(userId);
      return Right(codes?.remainingCount ?? 0);
    } catch (e) {
      return const Right(0);
    }
  }

  @override
  Future<Either<Failure, void>> storeSecret(String userId, String secret) async {
    try {
      await _localDataSource.storeSecret(userId, secret);
      return const Right(null);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to store secret: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getSecret(String userId) async {
    try {
      final secret = await _localDataSource.getSecret(userId);
      return Right(secret);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to get secret: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearSecret(String userId) async {
    try {
      await _localDataSource.clearSecret(userId);
      return const Right(null);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to clear secret: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> storePendingSecret(
    String userId,
    String secret,
  ) async {
    try {
      await _localDataSource.storePendingSecret(userId, secret);
      return const Right(null);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to store pending secret: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingSecret(String userId) async {
    try {
      final secret = await _localDataSource.getPendingSecret(userId);
      return Right(secret);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to get pending secret: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearPendingSecret(String userId) async {
    try {
      await _localDataSource.clearPendingSecret(userId);
      await _localDataSource.clearPendingRecoveryCodes(userId);
      return const Right(null);
    } catch (e) {
      return Left(TotpFailure(failureMessage: 'Failed to clear pending secret: $e'));
    }
  }

  // ============ Private Helper Methods ============

  /// Generate a cryptographically secure random secret (20 bytes = 160 bits)
  String _generateRandomSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes));
  }

  /// Generate otpauth:// URI for QR code
  String _generateQrUri(String email, String secret) {
    final encodedEmail = Uri.encodeComponent(email);
    final encodedIssuer = Uri.encodeComponent(_issuer);
    return 'otpauth://totp/$encodedIssuer:$encodedEmail'
        '?secret=$secret'
        '&issuer=$encodedIssuer'
        '&algorithm=SHA1'
        '&digits=$_totpDigits'
        '&period=$_totpInterval';
  }

  /// Format secret for display with spaces for readability
  String _formatSecretForDisplay(String secret) {
    // Insert space every 4 characters
    final buffer = StringBuffer();
    for (int i = 0; i < secret.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(secret[i]);
    }
    return buffer.toString();
  }

  /// Validate TOTP code with time window tolerance
  bool _validateTotp(String secret, String code, {int window = 1}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check current time window and adjacent windows
    for (int i = -window; i <= window; i++) {
      final timeMs = now + (i * _totpInterval * 1000);
      final expectedCode = OTP.generateTOTPCodeString(
        secret,
        timeMs,
        algorithm: Algorithm.SHA1,
        length: _totpDigits,
        interval: _totpInterval,
      );

      if (expectedCode == code) {
        return true;
      }
    }

    return false;
  }

  /// Generate random recovery codes
  List<String> _generateRecoveryCodes() {
    final random = Random.secure();
    return List.generate(_recoveryCodeCount, (_) {
      final bytes =
          List<int>.generate(_recoveryCodeLength, (_) => random.nextInt(256));
      // Format as uppercase hex with hyphen in middle for readability
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final upper = hex.toUpperCase();
      return '${upper.substring(0, 8)}-${upper.substring(8)}';
    });
  }

  /// Hash a recovery code for storage (SHA-256)
  String _hashRecoveryCode(String code) {
    // Normalize: uppercase, remove spaces and hyphens
    final normalized = code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
