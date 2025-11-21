import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../entities/auth_token_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Stream<Either<Failure, UserEntity>> watchKycStatus(
    String userId,
  );

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, bool>> hasValidSession();

  Future<Either<Failure, AuthTokenEntity?>> getStoredToken();

  Future<Either<Failure, void>> storeToken(AuthTokenEntity token);

  Future<Either<Failure, void>> clearStoredData();

  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user);

  Future<Either<Failure, void>> resetPassword(String email);
}