import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_token_entity.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthUseCase {
  final authRepo = AuthRepositoryImpl();

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) {
    return authRepo.signInWithEmailAndPassword(email, password);
  }
  Stream<Either<Failure, UserModel>> watchKycStatus(
    String userId,
  ) {
    return authRepo.watchUserData(userId);
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

  Future<Either<Failure, void>> updateUserProfile(UserEntity user) {
    return authRepo.updateUserProfile(user);
  }

  Future<Either<Failure, void>> resetPassword(String email) {
    return authRepo.resetPassword(email);
  }
}
