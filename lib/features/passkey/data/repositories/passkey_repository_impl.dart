import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/passkey_entity.dart';
import '../../domain/entities/passkey_auth_result.dart';
import '../../domain/repositories/passkey_repository.dart';
import '../datasources/passkey_remote_data_source.dart';

/// Implementation of PasskeyRepository
class PasskeyRepositoryImpl implements PasskeyRepository {
  final PasskeyRemoteDataSource _remoteDataSource;

  PasskeyRepositoryImpl({PasskeyRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? GetIt.instance<PasskeyRemoteDataSource>();

  @override
  Future<Either<Failure, bool>> isPasskeySupported() {
    return ErrorHandler.handle(
      () => _remoteDataSource.isPasskeySupported(),
      operationName: 'isPasskeySupported',
    );
  }

  @override
  Future<Either<Failure, PasskeyAuthResult>> signUpWithPasskey(String email) {
    return ErrorHandler.handle(
      () async {
        final result = await _remoteDataSource.signUpWithPasskey(email);
        return result.toEntity();
      },
      operationName: 'signUpWithPasskey',
    );
  }

  @override
  Future<Either<Failure, PasskeyAuthResult>> signInWithPasskey() {
    return ErrorHandler.handle(
      () async {
        final result = await _remoteDataSource.signInWithPasskey();
        return result.toEntity();
      },
      operationName: 'signInWithPasskey',
    );
  }

  @override
  Future<Either<Failure, PasskeyEntity>> appendPasskey() {
    return ErrorHandler.handle(
      () async {
        final result = await _remoteDataSource.appendPasskey();
        return result.toEntity();
      },
      operationName: 'appendPasskey',
    );
  }

  @override
  Future<Either<Failure, List<PasskeyEntity>>> getPasskeys() {
    return ErrorHandler.handle(
      () async {
        final passkeys = await _remoteDataSource.getPasskeys();
        return passkeys.map((p) => p.toEntity()).toList();
      },
      operationName: 'getPasskeys',
    );
  }

  @override
  Future<Either<Failure, void>> removePasskey(String credentialId) {
    return ErrorHandler.handle(
      () => _remoteDataSource.removePasskey(credentialId),
      operationName: 'removePasskey',
    );
  }

  @override
  Future<Either<Failure, bool>> hasRegisteredPasskeys() {
    return ErrorHandler.handle(
      () => _remoteDataSource.hasRegisteredPasskeys(),
      operationName: 'hasRegisteredPasskeys',
    );
  }

  @override
  Future<Either<Failure, void>> signOut() {
    return ErrorHandler.handle(
      () => _remoteDataSource.signOut(),
      operationName: 'passkeySignOut',
    );
  }

  @override
  Future<Either<Failure, PasskeyAuthResult?>> getCurrentUser() {
    return ErrorHandler.handle(
      () async {
        final result = await _remoteDataSource.getCurrentUser();
        return result?.toEntity();
      },
      operationName: 'getCurrentPasskeyUser',
    );
  }

  @override
  Stream<PasskeyAuthResult?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map((model) => model?.toEntity());
}
