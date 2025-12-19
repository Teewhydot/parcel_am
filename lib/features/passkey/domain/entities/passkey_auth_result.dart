import 'package:equatable/equatable.dart';

/// Result of passkey authentication containing user information
class PasskeyAuthResult extends Equatable {
  /// The user's unique identifier from Corbado
  final String corbadoUserId;

  /// The user's email address
  final String email;

  /// The user's display name (if available)
  final String? displayName;

  /// Whether this is a new user registration or existing user login
  final bool isNewUser;

  /// The authentication token for the session
  final String? authToken;

  const PasskeyAuthResult({
    required this.corbadoUserId,
    required this.email,
    this.displayName,
    this.isNewUser = false,
    this.authToken,
  });

  PasskeyAuthResult copyWith({
    String? corbadoUserId,
    String? email,
    String? displayName,
    bool? isNewUser,
    String? authToken,
  }) {
    return PasskeyAuthResult(
      corbadoUserId: corbadoUserId ?? this.corbadoUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isNewUser: isNewUser ?? this.isNewUser,
      authToken: authToken ?? this.authToken,
    );
  }

  @override
  List<Object?> get props => [
        corbadoUserId,
        email,
        displayName,
        isNewUser,
        authToken,
      ];
}
