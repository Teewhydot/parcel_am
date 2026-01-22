import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../models/totp_settings_model.dart';
import '../models/recovery_code_model.dart';

/// Remote data source for TOTP settings stored in Firestore
abstract class TotpRemoteDataSource {
  /// Get TOTP settings for a user
  Future<TotpSettingsModel?> getSettings(String userId);

  /// Create or update TOTP settings for a user
  Future<void> updateSettings(TotpSettingsModel settings);

  /// Delete TOTP settings for a user
  Future<void> deleteSettings(String userId);

  /// Store hashed recovery codes for a user
  Future<void> storeRecoveryCodes(String userId, List<RecoveryCodeModel> codes);

  /// Get recovery codes for a user
  Future<RecoveryCodesModel?> getRecoveryCodes(String userId);

  /// Mark a recovery code as used
  Future<void> markRecoveryCodeUsed(String userId, String codeHash);

  /// Delete all recovery codes for a user
  Future<void> deleteRecoveryCodes(String userId);

  /// Increment failed attempts counter
  Future<TotpSettingsModel> incrementFailedAttempts(
    String userId,
    int currentAttempts,
  );

  /// Reset failed attempts counter
  Future<void> resetFailedAttempts(String userId);
}

/// Implementation using Firebase Firestore
class TotpRemoteDataSourceImpl implements TotpRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Firestore paths
  /// Settings: /users/{userId}/security/totp_settings
  /// Recovery codes: /users/{userId}/security/recovery_codes
  static const String _securityCollection = 'security';
  static const String _totpSettingsDoc = 'totp_settings';
  static const String _recoveryCodesDoc = 'recovery_codes';

  TotpRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? GetIt.instance<FirebaseFirestore>();

  /// Get reference to user's security subcollection
  CollectionReference<Map<String, dynamic>> _securityRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_securityCollection);
  }

  @override
  Future<TotpSettingsModel?> getSettings(String userId) async {
    final doc = await _securityRef(userId).doc(_totpSettingsDoc).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TotpSettingsModel.fromJson(doc.data()!);
  }

  @override
  Future<void> updateSettings(TotpSettingsModel settings) async {
    await _securityRef(settings.userId).doc(_totpSettingsDoc).set(
          settings.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteSettings(String userId) async {
    await _securityRef(userId).doc(_totpSettingsDoc).delete();
  }

  @override
  Future<void> storeRecoveryCodes(
    String userId,
    List<RecoveryCodeModel> codes,
  ) async {
    final model = RecoveryCodesModel(
      codes: codes,
      generatedAt: DateTime.now(),
    );

    await _securityRef(userId).doc(_recoveryCodesDoc).set(model.toJson());
  }

  @override
  Future<RecoveryCodesModel?> getRecoveryCodes(String userId) async {
    final doc = await _securityRef(userId).doc(_recoveryCodesDoc).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return RecoveryCodesModel.fromJson(doc.data()!);
  }

  @override
  Future<void> markRecoveryCodeUsed(String userId, String codeHash) async {
    final codesDoc = await _securityRef(userId).doc(_recoveryCodesDoc).get();

    if (!codesDoc.exists || codesDoc.data() == null) {
      return;
    }

    final model = RecoveryCodesModel.fromJson(codesDoc.data()!);

    // Find and update the matching code
    final updatedCodes = model.codes.map((code) {
      if (code.hash == codeHash && !code.isUsed) {
        return RecoveryCodeModel(
          hash: code.hash,
          isUsed: true,
          usedAt: DateTime.now(),
        );
      }
      return code;
    }).toList();

    final updatedModel = RecoveryCodesModel(
      codes: updatedCodes,
      generatedAt: model.generatedAt,
    );

    await _securityRef(userId).doc(_recoveryCodesDoc).set(updatedModel.toJson());
  }

  @override
  Future<void> deleteRecoveryCodes(String userId) async {
    await _securityRef(userId).doc(_recoveryCodesDoc).delete();
  }

  @override
  Future<TotpSettingsModel> incrementFailedAttempts(
    String userId,
    int currentAttempts,
  ) async {
    final newAttempts = currentAttempts + 1;
    DateTime? lockedUntil;

    // Lock account for 15 minutes after 5 failed attempts
    if (newAttempts >= 5) {
      lockedUntil = DateTime.now().add(const Duration(minutes: 15));
    }

    final settings = TotpSettingsModel(
      id: userId,
      userId: userId,
      isEnabled: true,
      failedAttempts: newAttempts,
      lockedUntil: lockedUntil,
    );

    await _securityRef(userId).doc(_totpSettingsDoc).update({
      'failedAttempts': newAttempts,
      'lockedUntil':
          lockedUntil != null ? Timestamp.fromDate(lockedUntil) : null,
    });

    return settings;
  }

  @override
  Future<void> resetFailedAttempts(String userId) async {
    await _securityRef(userId).doc(_totpSettingsDoc).update({
      'failedAttempts': 0,
      'lockedUntil': null,
      'lastVerifiedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
