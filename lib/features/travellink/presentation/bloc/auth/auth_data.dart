import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

/// Data class to hold authentication-specific properties
class AuthData extends Equatable {
  final UserEntity? user;
  final String email;
  final String password;

  const AuthData({
    this.user,
    this.email = '',
    this.password = '',
  });

  AuthData copyWith({
    UserEntity? user,
    String? email,
    String? password,
  }) {
    return AuthData(
      user: user ?? this.user,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isEmailValid => email.isNotEmpty && email.contains('@');
  bool get isPasswordValid => password.isNotEmpty && password.length >= 6;

  @override
  List<Object?> get props => [user, email, password];
}