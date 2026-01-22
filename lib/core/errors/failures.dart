import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String failureMessage;
  
  const Failure({required this.failureMessage});

  @override
  List<Object> get props => [failureMessage];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.failureMessage});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.failureMessage});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.failureMessage});
}

class NoInternetFailure extends Failure {
  const NoInternetFailure({required super.failureMessage});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.failureMessage});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.failureMessage});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.failureMessage});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.failureMessage});
}

class FirebaseAuthFailure extends AuthFailure {
  const FirebaseAuthFailure({required super.failureMessage});
}

class PhoneAuthFailure extends AuthFailure {
  const PhoneAuthFailure({required super.failureMessage});
}

class TokenExpiredFailure extends AuthFailure {
  const TokenExpiredFailure({required super.failureMessage});
}
class InvalidDataFailure extends Failure {
  const InvalidDataFailure({required super.failureMessage});
}

// Passkey-specific failures
class PasskeyFailure extends Failure {
  const PasskeyFailure({required super.failureMessage});
}

class PasskeyNotSupportedFailure extends PasskeyFailure {
  const PasskeyNotSupportedFailure({
    super.failureMessage = 'Passkeys are not supported on this device',
  });
}

class PasskeyRegistrationFailure extends PasskeyFailure {
  const PasskeyRegistrationFailure({required super.failureMessage});
}

class PasskeyAuthenticationFailure extends PasskeyFailure {
  const PasskeyAuthenticationFailure({required super.failureMessage});
}

class PasskeyCancelledFailure extends PasskeyFailure {
  const PasskeyCancelledFailure({
    super.failureMessage = 'Passkey operation was cancelled',
  });
}

class PasskeyAlreadyExistsFailure extends PasskeyFailure {
  const PasskeyAlreadyExistsFailure({
    super.failureMessage = 'A passkey is already registered for this device',
  });
}

// TOTP 2FA-specific failures
class TotpFailure extends Failure {
  const TotpFailure({required super.failureMessage});
}

class TotpSetupFailure extends TotpFailure {
  const TotpSetupFailure({required super.failureMessage});
}

class TotpVerificationFailure extends TotpFailure {
  const TotpVerificationFailure({
    super.failureMessage = 'Invalid verification code',
  });
}

class TotpLockedFailure extends TotpFailure {
  final DateTime lockedUntil;

  const TotpLockedFailure({
    required super.failureMessage,
    required this.lockedUntil,
  });

  @override
  List<Object> get props => [failureMessage, lockedUntil];
}

class TotpNotConfiguredFailure extends TotpFailure {
  const TotpNotConfiguredFailure({
    super.failureMessage = 'Two-factor authentication is not configured',
  });
}

class RecoveryCodeFailure extends TotpFailure {
  const RecoveryCodeFailure({required super.failureMessage});
}

class RecoveryCodeExhaustedFailure extends RecoveryCodeFailure {
  const RecoveryCodeExhaustedFailure({
    super.failureMessage = 'All recovery codes have been used',
  });
}