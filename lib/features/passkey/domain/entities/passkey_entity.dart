import 'package:equatable/equatable.dart';

/// Entity representing a registered passkey credential
class PasskeyEntity extends Equatable {
  final String id;
  final String credentialId;
  final String userId;
  final String? userAgent;
  final String? deviceName;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  const PasskeyEntity({
    required this.id,
    required this.credentialId,
    required this.userId,
    this.userAgent,
    this.deviceName,
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = true,
  });

  PasskeyEntity copyWith({
    String? id,
    String? credentialId,
    String? userId,
    String? userAgent,
    String? deviceName,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return PasskeyEntity(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      userId: userId ?? this.userId,
      userAgent: userAgent ?? this.userAgent,
      deviceName: deviceName ?? this.deviceName,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        credentialId,
        userId,
        userAgent,
        deviceName,
        createdAt,
        lastUsedAt,
        isActive,
      ];
}
