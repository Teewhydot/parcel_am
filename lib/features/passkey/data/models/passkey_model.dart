import '../../domain/entities/passkey_entity.dart';

/// Data model for PasskeyEntity with JSON serialization
class PasskeyModel extends PasskeyEntity {
  const PasskeyModel({
    required super.id,
    required super.credentialId,
    required super.userId,
    super.userAgent,
    super.deviceName,
    required super.createdAt,
    super.lastUsedAt,
    super.isActive = true,
  });

  /// Create model from JSON map
  factory PasskeyModel.fromJson(Map<String, dynamic> json) {
    return PasskeyModel(
      id: json['id'] as String,
      credentialId: json['credentialId'] as String,
      userId: json['userId'] as String,
      userAgent: json['userAgent'] as String?,
      deviceName: json['deviceName'] as String?,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? (json['lastUsedAt'] is DateTime
              ? json['lastUsedAt'] as DateTime
              : DateTime.parse(json['lastUsedAt'] as String))
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert model to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credentialId': credentialId,
      'userId': userId,
      'userAgent': userAgent,
      'deviceName': deviceName,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Convert to domain entity
  PasskeyEntity toEntity() {
    return PasskeyEntity(
      id: id,
      credentialId: credentialId,
      userId: userId,
      userAgent: userAgent,
      deviceName: deviceName,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      isActive: isActive,
    );
  }

  /// Create model from domain entity
  factory PasskeyModel.fromEntity(PasskeyEntity entity) {
    return PasskeyModel(
      id: entity.id,
      credentialId: entity.credentialId,
      userId: entity.userId,
      userAgent: entity.userAgent,
      deviceName: entity.deviceName,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
      isActive: entity.isActive,
    );
  }
}
