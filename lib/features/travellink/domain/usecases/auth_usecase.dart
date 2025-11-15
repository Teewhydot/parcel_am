import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_token_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository authRepo;

  AuthUseCase(this.authRepo);

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) {
    return authRepo.signInWithEmailAndPassword(email, password);
  }

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return authRepo.signUpWithEmailAndPassword(email, password, displayName);
  }

  Future<Either<Failure, void>> logout() {
    return authRepo.signOut();
  }

  Future<Either<Failure, UserEntity?>> getCurrentUser() {
    return authRepo.getCurrentUser();
  }

  Future<Either<Failure, bool>> hasValidSession() {
    return authRepo.hasValidSession();
  }

  Future<Either<Failure, AuthTokenEntity?>> getStoredToken() {
    return authRepo.getStoredToken();
  }

  Future<Either<Failure, void>> storeToken(AuthTokenEntity token) {
    return authRepo.storeToken(token);
  }

  Future<Either<Failure, void>> clearStoredData() {
    return authRepo.clearStoredData();
  }

  Stream<UserEntity?> get authStateChanges => authRepo.authStateChanges;

  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user) {
    return authRepo.updateUserProfile(user);
  }

  Future<Either<Failure, void>> resetPassword(String email) {
    return authRepo.resetPassword(email);
  }
}
