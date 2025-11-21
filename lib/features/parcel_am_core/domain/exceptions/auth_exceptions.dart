class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('User not found');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('Password is too weak');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super('Email is already in use');
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('Invalid email address');
}

class PhoneAuthException extends AuthException {
  const PhoneAuthException(super.message);
}

class InvalidVerificationCodeException extends PhoneAuthException {
  const InvalidVerificationCodeException() : super('Invalid verification code');
}

class InvalidPhoneNumberException extends PhoneAuthException {
  const InvalidPhoneNumberException() : super('Invalid phone number');
}

class TokenExpiredException extends AuthException {
  const TokenExpiredException() : super('Authentication token has expired');
}

class NetworkException extends AuthException {
  const NetworkException() : super('Network connection error');
}

class ServerException implements Exception {
  final String message;
  const ServerException([String? message]) : message = message ?? 'Server error occurred';

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([String? message]) : message = message ?? 'Cache error occurred';

  @override
  String toString() => 'CacheException: $message';
}