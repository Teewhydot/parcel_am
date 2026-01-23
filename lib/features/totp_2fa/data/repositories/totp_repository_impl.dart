import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:parcel_am/core/services/error/error_handler.dart';
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
  ) {
    return ErrorHandler.handle(
      () async {
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

        return TotpSetupResult(
          secretForDisplay: _formatSecretForDisplay(secret),
          secret: secret,
          qrCodeUri: qrCodeUri,
          recoveryCodes: recoveryCodes,
        );
      },
      operationName: 'generateSecret',
    );
  }

  @override
  Future<Either<Failure, bool>> verifySetupCode(
    String userId,
    String code,
  ) {
    return ErrorHandler.handle(
      () async {
        // Get pending secret
        final pendingSecret = await _localDataSource.getPendingSecret(userId);
        if (pendingSecret == null) {
          throw const TotpSetupFailure(
            failureMessage: 'No pending 2FA setup found. Please start setup again.',
          );
        }

        // Validate TOTP code
        if (!_validateTotp(pendingSecret, code)) {
          throw const TotpVerificationFailure(
            failureMessage: 'Invalid verification code. Please try again.',
          );
        }

        // Get pending recovery codes
        final pendingRecoveryCodes =
            await _localDataSource.getPendingRecoveryCodes(userId);
        if (pendingRecoveryCodes == null || pendingRecoveryCodes.isEmpty) {
          throw const TotpSetupFailure(
            failureMessage: 'Recovery codes not found. Please restart setup.',
          );
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

        return true;
      },
      operationName: 'verifySetupCode',
    );
  }

  @override
  Future<Either<Failure, TotpVerificationResult>> verifyCode(
    String userId,
    String code,
  ) {
    return ErrorHandler.handle(
      () async {
        // Check if user has 2FA enabled and not locked
        final settings = await _remoteDataSource.getSettings(userId);
        if (settings == null || !settings.isEnabled) {
          throw const TotpNotConfiguredFailure();
        }

        // Check if account is locked
        if (settings.isLocked) {
          throw TotpLockedFailure(
            failureMessage:
                'Too many failed attempts. Please try again in ${settings.remainingLockMinutes} minutes.',
            lockedUntil: settings.lockedUntil!,
          );
        }

        // Get stored secret
        final secret = await _localDataSource.getSecret(userId);
        if (secret == null) {
          throw const TotpNotConfiguredFailure(
            failureMessage: '2FA secret not found on this device. Please disable and re-enable 2FA.',
          );
        }

        // Validate TOTP code
        final isValid = _validateTotp(secret, code);

        if (isValid) {
          // Reset failed attempts on success
          await _remoteDataSource.resetFailedAttempts(userId);
          return const TotpVerificationResult(
            isValid: true,
            isRecoveryCode: false,
          );
        } else {
          // Increment failed attempts
          await _remoteDataSource.incrementFailedAttempts(
            userId,
            settings.failedAttempts,
          );
          throw const TotpVerificationFailure();
        }
      },
      operationName: 'verifyCode',
    );
  }

  @override
  Future<Either<Failure, TotpVerificationResult>> verifyRecoveryCode(
    String userId,
    String code,
  ) {
    return ErrorHandler.handle(
      () async {
        // Check if user has 2FA enabled
        final settings = await _remoteDataSource.getSettings(userId);
        if (settings == null || !settings.isEnabled) {
          throw const TotpNotConfiguredFailure();
        }

        // Get recovery codes
        final recoveryCodes = await _remoteDataSource.getRecoveryCodes(userId);
        if (recoveryCodes == null) {
          throw const RecoveryCodeFailure(
            failureMessage: 'No recovery codes found',
          );
        }

        // Check if all codes are exhausted
        if (recoveryCodes.isExhausted) {
          throw const RecoveryCodeExhaustedFailure();
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
          throw const RecoveryCodeFailure(
            failureMessage: 'Invalid recovery code',
          );
        }

        // Mark the code as used
        await _remoteDataSource.markRecoveryCodeUsed(userId, inputHash);

        // Reset failed attempts
        await _remoteDataSource.resetFailedAttempts(userId);

        // Get updated count
        final updatedCodes = await _remoteDataSource.getRecoveryCodes(userId);
        final remainingCount = updatedCodes?.remainingCount ?? 0;

        return TotpVerificationResult(
          isValid: true,
          isRecoveryCode: true,
          remainingRecoveryCodes: remainingCount,
        );
      },
      operationName: 'verifyRecoveryCode',
    );
  }

  @override
  Future<Either<Failure, TotpSettingsEntity?>> getSettings(String userId) {
    return ErrorHandler.handle(
      () async {
        final settings = await _remoteDataSource.getSettings(userId);
        return settings?.toEntity();
      },
      operationName: 'getSettings',
    );
  }

  @override
  Future<Either<Failure, bool>> is2FAEnabled(String userId) {
    return ErrorHandler.handle(
      () async {
        final settings = await _remoteDataSource.getSettings(userId);
        return settings?.isEnabled ?? false;
      },
      operationName: 'is2FAEnabled',
    );
  }

  @override
  Future<Either<Failure, void>> disable2FA(String userId) {
    return ErrorHandler.handle(
      () async {
        // Clear local secret
        await _localDataSource.clearSecret(userId);

        // Delete Firestore settings
        await _remoteDataSource.deleteSettings(userId);

        // Delete recovery codes
        await _remoteDataSource.deleteRecoveryCodes(userId);
      },
      operationName: 'disable2FA',
    );
  }

  @override
  Future<Either<Failure, List<String>>> regenerateRecoveryCodes(
    String userId,
  ) {
    return ErrorHandler.handle(
      () async {
        // Check if 2FA is enabled
        final settings = await _remoteDataSource.getSettings(userId);
        if (settings == null || !settings.isEnabled) {
          throw const TotpNotConfiguredFailure();
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

        return newCodes;
      },
      operationName: 'regenerateRecoveryCodes',
    );
  }

  @override
  Future<Either<Failure, int>> getRemainingRecoveryCodesCount(
    String userId,
  ) {
    return ErrorHandler.handle(
      () async {
        final codes = await _remoteDataSource.getRecoveryCodes(userId);
        return codes?.remainingCount ?? 0;
      },
      operationName: 'getRemainingRecoveryCodesCount',
    );
  }

  @override
  Future<Either<Failure, void>> storeSecret(String userId, String secret) {
    return ErrorHandler.handle(
      () async {
        await _localDataSource.storeSecret(userId, secret);
      },
      operationName: 'storeSecret',
    );
  }

  @override
  Future<Either<Failure, String?>> getSecret(String userId) {
    return ErrorHandler.handle(
      () async {
        final secret = await _localDataSource.getSecret(userId);
        return secret;
      },
      operationName: 'getSecret',
    );
  }

  @override
  Future<Either<Failure, void>> clearSecret(String userId) {
    return ErrorHandler.handle(
      () async {
        await _localDataSource.clearSecret(userId);
      },
      operationName: 'clearSecret',
    );
  }

  @override
  Future<Either<Failure, void>> storePendingSecret(
    String userId,
    String secret,
  ) {
    return ErrorHandler.handle(
      () async {
        await _localDataSource.storePendingSecret(userId, secret);
      },
      operationName: 'storePendingSecret',
    );
  }

  @override
  Future<Either<Failure, String?>> getPendingSecret(String userId) {
    return ErrorHandler.handle(
      () async {
        final secret = await _localDataSource.getPendingSecret(userId);
        return secret;
      },
      operationName: 'getPendingSecret',
    );
  }

  @override
  Future<Either<Failure, void>> clearPendingSecret(String userId) {
    return ErrorHandler.handle(
      () async {
        await _localDataSource.clearPendingSecret(userId);
        await _localDataSource.clearPendingRecoveryCodes(userId);
      },
      operationName: 'clearPendingSecret',
    );
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
