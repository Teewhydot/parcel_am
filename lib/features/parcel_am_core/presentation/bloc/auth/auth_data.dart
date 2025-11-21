import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

/// Data class to hold authentication-specific properties
class AuthData extends Equatable {
  final UserEntity? user;
  final String email;
  final String password;
  final String? verificationId;
  final int? resendToken;

  const AuthData({
    this.user,
    this.email = '',
    this.password = '',
    this.verificationId,
    this.resendToken,
  });

  AuthData copyWith({
    UserEntity? user,
    String? email,
    String? password,
    String? verificationId,
    int? resendToken,
  }) {
    return AuthData(
      user: user ?? this.user,
      email: email ?? this.email,
      password: password ?? this.password,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isEmailValid {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  bool get isPasswordValid => password.isNotEmpty && password.length >= 6;

  @override
  List<Object?> get props => [
        user,
        email,
        password,
        verificationId,
        resendToken,
      ];
}
