import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class AuthPhoneNumberChanged extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneNumberChanged(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class AuthOtpChanged extends AuthEvent {
  final String otp;

  const AuthOtpChanged(this.otp);

  @override
  List<Object> get props => [otp];
}

class AuthSendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const AuthSendOtpRequested(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String phoneNumber;
  final String otp;

  const AuthVerifyOtpRequested({
    required this.phoneNumber,
    required this.otp,
  });

  @override
  List<Object> get props => [phoneNumber, otp];
}

class AuthResendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const AuthResendOtpRequested(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class AuthAutoVerificationCompleted extends AuthEvent {
  final PhoneAuthCredential credential;

  const AuthAutoVerificationCompleted(this.credential);

  @override
  List<Object> get props => [credential];
}

class AuthCodeSent extends AuthEvent {
  final String verificationId;
  final int? resendToken;

  const AuthCodeSent(this.verificationId, this.resendToken);

  @override
  List<Object?> get props => [verificationId, resendToken];
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
  final String email;

  const AuthUserProfileUpdateRequested({
    required this.displayName,
    required this.email,
  });

  @override
  List<Object> get props => [displayName, email];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthUpdateResendCooldown extends AuthEvent {
  final int cooldown;

  const AuthUpdateResendCooldown(this.cooldown);

  @override
  List<Object> get props => [cooldown];
}

class AuthEnableResendOtp extends AuthEvent {
  const AuthEnableResendOtp();
}