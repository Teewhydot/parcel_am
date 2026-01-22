import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_token_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase({AuthRepository? repository})
      : _repository = repository ?? GetIt.instance<AuthRepository>();

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) {
    return _repository.signInWithEmailAndPassword(email, password);
  }
  Stream<Either<Failure, UserEntity>> watchKycStatus(
    String userId,
  ) {
    return _repository.watchUserData(userId);
  }

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUpWithEmailAndPassword(email, password, displayName);
  }

  Future<Either<Failure, void>> logout() {
    return _repository.signOut();
  }

  Future<Either<Failure, UserEntity?>> getCurrentUser() {
    return _repository.getCurrentUser();
  }

  Future<Either<Failure, bool>> hasValidSession() {
    return _repository.hasValidSession();
  }

  Future<Either<Failure, AuthTokenEntity?>> getStoredToken() {
    return _repository.getStoredToken();
  }

  Future<Either<Failure, void>> storeToken(AuthTokenEntity token) {
    return _repository.storeToken(token);
  }

  Future<Either<Failure, void>> clearStoredData() {
    return _repository.clearStoredData();
  }

  Stream<UserEntity?> get authStateChanges => _repository.authStateChanges;

  Future<Either<Failure, void>> updateUserProfile(UserEntity user) {
    return _repository.updateUserProfile(user);
  }

  Future<Either<Failure, void>> resetPassword(String email) {
    return _repository.resetPassword(email);
  }
}
