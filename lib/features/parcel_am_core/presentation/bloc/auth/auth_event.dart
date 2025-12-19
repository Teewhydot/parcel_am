import 'package:equatable/equatable.dart';
import 'package:parcel_am/core/domain/entities/kyc_status.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthEmailChanged extends AuthEvent {
  final String email;

  const AuthEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class AuthPasswordChanged extends AuthEvent {
  final String password;

  const AuthPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckAuthState extends AuthEvent {
  const AuthCheckAuthState();
}

class AuthRestoreStateRequested extends AuthEvent {
  const AuthRestoreStateRequested();
}

class AuthUserProfileUpdateRequested extends AuthEvent {
  final String displayName;
  final KycStatus? kycStatus;
  final Map<String, dynamic>? additionalData;

  const AuthUserProfileUpdateRequested({
    required this.displayName,
     this.kycStatus,
    this.additionalData,
  });

  @override
  List<Object?> get props => [displayName, kycStatus, additionalData];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthKycStatusUpdated extends AuthEvent {
  final String kycStatus;

  const AuthKycStatusUpdated(this.kycStatus);

  @override
  List<Object> get props => [kycStatus];
}

/// Event to check if passkeys are supported on this device
class AuthPasskeyCheckSupport extends AuthEvent {
  const AuthPasskeyCheckSupport();
}

/// Event to sign in with passkey
class AuthPasskeySignInRequested extends AuthEvent {
  const AuthPasskeySignInRequested();
}

/// Event to handle successful passkey authentication
/// Links the passkey user with Firebase user
class AuthPasskeySignInCompleted extends AuthEvent {
  final String corbadoUserId;
  final String email;
  final String? displayName;

  const AuthPasskeySignInCompleted({
    required this.corbadoUserId,
    required this.email,
    this.displayName,
  });

  @override
  List<Object?> get props => [corbadoUserId, email, displayName];
}