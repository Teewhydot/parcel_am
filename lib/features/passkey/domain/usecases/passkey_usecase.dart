import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/passkey_entity.dart';
import '../entities/passkey_auth_result.dart';
import '../repositories/passkey_repository.dart';

/// Use case for passkey authentication operations
class PasskeyUseCase {
  final PasskeyRepository _repository;

  PasskeyUseCase({PasskeyRepository? repository})
      : _repository = repository ?? GetIt.instance<PasskeyRepository>();

  /// Check if passkeys are supported on this device
  Future<Either<Failure, bool>> isPasskeySupported() {
    return _repository.isPasskeySupported();
  }

  /// Sign up a new user with passkey
  Future<Either<Failure, PasskeyAuthResult>> signUpWithPasskey(String email) {
    return _repository.signUpWithPasskey(email);
  }

  /// Sign in an existing user with passkey
  Future<Either<Failure, PasskeyAuthResult>> signInWithPasskey() {
    return _repository.signInWithPasskey();
  }

  /// Append a new passkey to the current user's account
  Future<Either<Failure, PasskeyEntity>> appendPasskey() {
    return _repository.appendPasskey();
  }

  /// Get all passkeys for the current user
  Future<Either<Failure, List<PasskeyEntity>>> getPasskeys() {
    return _repository.getPasskeys();
  }

  /// Remove a passkey by its credential ID
  Future<Either<Failure, void>> removePasskey(String credentialId) {
    return _repository.removePasskey(credentialId);
  }

  /// Check if user has any registered passkeys
  Future<Either<Failure, bool>> hasRegisteredPasskeys() {
    return _repository.hasRegisteredPasskeys();
  }

  /// Sign out from passkey session
  Future<Either<Failure, void>> signOut() {
    return _repository.signOut();
  }

  /// Get current authenticated user
  Future<Either<Failure, PasskeyAuthResult?>> getCurrentUser() {
    return _repository.getCurrentUser();
  }

  /// Stream of auth state changes
  Stream<PasskeyAuthResult?> get authStateChanges =>
      _repository.authStateChanges;
}
