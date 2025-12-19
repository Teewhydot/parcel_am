import 'package:equatable/equatable.dart';
import '../../domain/entities/passkey_entity.dart';
import '../../domain/entities/passkey_auth_result.dart';

/// Data class holding passkey-related state
class PasskeyData extends Equatable {
  /// Whether passkeys are supported on this device
  final bool isSupported;

  /// Whether the current user has registered passkeys
  final bool hasPasskeys;

  /// List of registered passkeys for the current user
  final List<PasskeyEntity> passkeys;

  /// The current authenticated user via passkey
  final PasskeyAuthResult? authResult;

  /// Email for passkey signup
  final String email;

  const PasskeyData({
    this.isSupported = false,
    this.hasPasskeys = false,
    this.passkeys = const [],
    this.authResult,
    this.email = '',
  });

  PasskeyData copyWith({
    bool? isSupported,
    bool? hasPasskeys,
    List<PasskeyEntity>? passkeys,
    PasskeyAuthResult? authResult,
    String? email,
  }) {
    return PasskeyData(
      isSupported: isSupported ?? this.isSupported,
      hasPasskeys: hasPasskeys ?? this.hasPasskeys,
      passkeys: passkeys ?? this.passkeys,
      authResult: authResult ?? this.authResult,
      email: email ?? this.email,
    );
  }

  /// Check if user is authenticated via passkey
  bool get isAuthenticated => authResult != null;

  /// Check if email is valid for signup
  bool get isEmailValid {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  List<Object?> get props => [
        isSupported,
        hasPasskeys,
        passkeys,
        authResult,
        email,
      ];
}
