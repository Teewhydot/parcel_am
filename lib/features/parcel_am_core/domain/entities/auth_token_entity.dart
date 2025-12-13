import 'package:equatable/equatable.dart';

class AuthTokenEntity extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String tokenType;

  const AuthTokenEntity({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AuthTokenEntity.fromJson(Map<String, dynamic> json) {
    return AuthTokenEntity(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      tokenType: json['tokenType'] as String? ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'tokenType': tokenType,
    };
  }

  AuthTokenEntity copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
  }) {
    return AuthTokenEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, tokenType];
}