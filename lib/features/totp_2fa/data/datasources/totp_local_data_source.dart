import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local data source for secure storage of TOTP secrets
/// Uses flutter_secure_storage for encrypted storage on device
abstract class TotpLocalDataSource {
  /// Store the verified TOTP secret for a user
  Future<void> storeSecret(String userId, String secret);

  /// Get the stored TOTP secret for a user
  Future<String?> getSecret(String userId);

  /// Clear the stored TOTP secret for a user
  Future<void> clearSecret(String userId);

  /// Store a pending secret during setup (before verification)
  Future<void> storePendingSecret(String userId, String secret);

  /// Get the pending secret during setup
  Future<String?> getPendingSecret(String userId);

  /// Clear the pending secret after setup or cancellation
  Future<void> clearPendingSecret(String userId);

  /// Store recovery codes temporarily during setup
  /// These are the plain text codes shown to user
  Future<void> storePendingRecoveryCodes(String userId, List<String> codes);

  /// Get pending recovery codes during setup
  Future<List<String>?> getPendingRecoveryCodes(String userId);

  /// Clear pending recovery codes after setup
  Future<void> clearPendingRecoveryCodes(String userId);
}

/// Implementation using flutter_secure_storage
class TotpLocalDataSourceImpl implements TotpLocalDataSource {
  final FlutterSecureStorage _storage;

  static const String _secretKeyPrefix = 'totp_secret_';
  static const String _pendingSecretKeyPrefix = 'totp_pending_secret_';
  static const String _pendingRecoveryCodesKeyPrefix = 'totp_pending_recovery_';

  TotpLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> storeSecret(String userId, String secret) async {
    await _storage.write(
      key: '$_secretKeyPrefix$userId',
      value: secret,
    );
  }

  @override
  Future<String?> getSecret(String userId) async {
    return await _storage.read(key: '$_secretKeyPrefix$userId');
  }

  @override
  Future<void> clearSecret(String userId) async {
    await _storage.delete(key: '$_secretKeyPrefix$userId');
  }

  @override
  Future<void> storePendingSecret(String userId, String secret) async {
    await _storage.write(
      key: '$_pendingSecretKeyPrefix$userId',
      value: secret,
    );
  }

  @override
  Future<String?> getPendingSecret(String userId) async {
    return await _storage.read(key: '$_pendingSecretKeyPrefix$userId');
  }

  @override
  Future<void> clearPendingSecret(String userId) async {
    await _storage.delete(key: '$_pendingSecretKeyPrefix$userId');
  }

  @override
  Future<void> storePendingRecoveryCodes(
    String userId,
    List<String> codes,
  ) async {
    // Store as comma-separated string
    final codesString = codes.join(',');
    await _storage.write(
      key: '$_pendingRecoveryCodesKeyPrefix$userId',
      value: codesString,
    );
  }

  @override
  Future<List<String>?> getPendingRecoveryCodes(String userId) async {
    final codesString = await _storage.read(
      key: '$_pendingRecoveryCodesKeyPrefix$userId',
    );
    if (codesString == null || codesString.isEmpty) return null;
    return codesString.split(',');
  }

  @override
  Future<void> clearPendingRecoveryCodes(String userId) async {
    await _storage.delete(key: '$_pendingRecoveryCodesKeyPrefix$userId');
  }
}
