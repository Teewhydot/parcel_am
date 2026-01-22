import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/totp_settings_entity.dart';

/// Data model for TOTP settings with Firestore serialization
class TotpSettingsModel extends TotpSettingsEntity {
  const TotpSettingsModel({
    required super.id,
    required super.userId,
    required super.isEnabled,
    super.enabledAt,
    super.lastVerifiedAt,
    super.failedAttempts,
    super.lockedUntil,
  });

  /// Create model from Firestore document data
  factory TotpSettingsModel.fromJson(Map<String, dynamic> json) {
    return TotpSettingsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? false,
      enabledAt: _parseTimestamp(json['enabledAt']),
      lastVerifiedAt: _parseTimestamp(json['lastVerifiedAt']),
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      lockedUntil: _parseTimestamp(json['lockedUntil']),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'isEnabled': isEnabled,
      'enabledAt': enabledAt != null ? Timestamp.fromDate(enabledAt!) : null,
      'lastVerifiedAt':
          lastVerifiedAt != null ? Timestamp.fromDate(lastVerifiedAt!) : null,
      'failedAttempts': failedAttempts,
      'lockedUntil':
          lockedUntil != null ? Timestamp.fromDate(lockedUntil!) : null,
    };
  }

  /// Create model from entity
  factory TotpSettingsModel.fromEntity(TotpSettingsEntity entity) {
    return TotpSettingsModel(
      id: entity.id,
      userId: entity.userId,
      isEnabled: entity.isEnabled,
      enabledAt: entity.enabledAt,
      lastVerifiedAt: entity.lastVerifiedAt,
      failedAttempts: entity.failedAttempts,
      lockedUntil: entity.lockedUntil,
    );
  }

  /// Convert to entity
  TotpSettingsEntity toEntity() {
    return TotpSettingsEntity(
      id: id,
      userId: userId,
      isEnabled: isEnabled,
      enabledAt: enabledAt,
      lastVerifiedAt: lastVerifiedAt,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
    );
  }

  /// Create a new settings model with initial values
  factory TotpSettingsModel.initial(String userId) {
    return TotpSettingsModel(
      id: userId,
      userId: userId,
      isEnabled: false,
      failedAttempts: 0,
    );
  }

  /// Helper to parse Firestore Timestamp or DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  TotpSettingsModel copyWith({
    String? id,
    String? userId,
    bool? isEnabled,
    DateTime? enabledAt,
    DateTime? lastVerifiedAt,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return TotpSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      enabledAt: enabledAt ?? this.enabledAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}
