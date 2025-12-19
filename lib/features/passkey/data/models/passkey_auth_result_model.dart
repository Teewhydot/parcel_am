import '../../domain/entities/passkey_auth_result.dart';

/// Data model for PasskeyAuthResult with JSON serialization
class PasskeyAuthResultModel extends PasskeyAuthResult {
  const PasskeyAuthResultModel({
    required super.corbadoUserId,
    required super.email,
    super.displayName,
    super.isNewUser = false,
    super.authToken,
  });

  /// Create model from JSON map
  factory PasskeyAuthResultModel.fromJson(Map<String, dynamic> json) {
    return PasskeyAuthResultModel(
      corbadoUserId: json['corbadoUserId'] as String? ?? json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      isNewUser: json['isNewUser'] as bool? ?? false,
      authToken: json['authToken'] as String?,
    );
  }

  /// Convert model to JSON map
  Map<String, dynamic> toJson() {
    return {
      'corbadoUserId': corbadoUserId,
      'email': email,
      'displayName': displayName,
      'isNewUser': isNewUser,
      'authToken': authToken,
    };
  }

  /// Convert to domain entity
  PasskeyAuthResult toEntity() {
    return PasskeyAuthResult(
      corbadoUserId: corbadoUserId,
      email: email,
      displayName: displayName,
      isNewUser: isNewUser,
      authToken: authToken,
    );
  }

  /// Create model from domain entity
  factory PasskeyAuthResultModel.fromEntity(PasskeyAuthResult entity) {
    return PasskeyAuthResultModel(
      corbadoUserId: entity.corbadoUserId,
      email: entity.email,
      displayName: entity.displayName,
      isNewUser: entity.isNewUser,
      authToken: entity.authToken,
    );
  }
}
