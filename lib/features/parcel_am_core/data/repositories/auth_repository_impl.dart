import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:parcel_am/core/services/error/error_handler.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_token_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final remoteDataSource = GetIt.instance<AuthRemoteDataSource>();

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
     final userModel = await remoteDataSource.signInWithEmailAndPassword(email, password);
        return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

@override
  Stream<Either<Failure, UserModel>> watchUserData(
    String userId,
  ) {
    return ErrorHandler.handleStream(
      () => remoteDataSource.watchUserDetails(userId),
      operationName: 'watchUserStatus',
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
     final userModel = await remoteDataSource.signUpWithEmailAndPassword(email, password, displayName);
        return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        remoteDataSource.signOut(),
      ]);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      
      if (user == null) {
        return const Right(null);
      }
    
      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidSession() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      
      if (user == null) {
        return const Right(false);
      }
      
      
      return const Right(true);
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokenEntity?>> getStoredToken() async {
    try {
    
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> storeToken(AuthTokenEntity token) async {
    try {
      // TODO: Implement token storage
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearStoredData() async {
    try {
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((userModel) {
      if (userModel != null) {
        return userModel.toEntity();
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user) async {
    try {
    final userModel = UserModel.fromEntity(user);
        final updatedUserModel = await remoteDataSource.updateUserProfile(userModel);
        return Right(updatedUserModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
       await remoteDataSource.resetPassword(email);
          return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }
}