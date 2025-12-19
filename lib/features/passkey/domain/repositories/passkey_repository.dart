import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/passkey_entity.dart';
import '../entities/passkey_auth_result.dart';

/// Repository interface for passkey authentication operations
abstract class PasskeyRepository {
  /// Check if passkeys are supported on this device
  Future<Either<Failure, bool>> isPasskeySupported();

  /// Sign up a new user with passkey and email
  /// Returns the authentication result with user information
  Future<Either<Failure, PasskeyAuthResult>> signUpWithPasskey(String email);

  /// Authenticate an existing user with passkey
  /// Returns the authentication result with user information
  Future<Either<Failure, PasskeyAuthResult>> signInWithPasskey();

  /// Append a new passkey to an existing authenticated user's account
  Future<Either<Failure, PasskeyEntity>> appendPasskey();

  /// Get all registered passkeys for the current user
  Future<Either<Failure, List<PasskeyEntity>>> getPasskeys();

  /// Remove a passkey by its credential ID
  Future<Either<Failure, void>> removePasskey(String credentialId);

  /// Check if the current user has any registered passkeys
  Future<Either<Failure, bool>> hasRegisteredPasskeys();

  /// Sign out from Corbado session
  Future<Either<Failure, void>> signOut();

  /// Get the current Corbado user if authenticated
  Future<Either<Failure, PasskeyAuthResult?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<PasskeyAuthResult?> get authStateChanges;
}
