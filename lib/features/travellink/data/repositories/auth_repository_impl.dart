import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_token_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';
import '../../../../core/network/network_info.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final userModel = await remoteDataSource.signInWithEmailAndPassword(email, password);
        await localDataSource.cacheUser(userModel);
        return Right(userModel.toEntity());
      } else {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
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
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final userModel = await remoteDataSource.signUpWithEmailAndPassword(email, password, displayName);
        await localDataSource.cacheUser(userModel);
        return Right(userModel.toEntity());
      } else {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
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
        localDataSource.clearAllCachedData(),
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
      final firebaseUser = await remoteDataSource.getCurrentUser();
      
      if (firebaseUser == null) {
        return const Right(null);
      }
      
      final cachedToken = await localDataSource.getCachedToken();
      
      if (cachedToken == null || cachedToken.toEntity().isExpired) {
        return const Right(null);
      }
      
      if (await networkInfo.isConnected) {
        await localDataSource.cacheUser(firebaseUser);
      }
      
      return Right(firebaseUser.toEntity());
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
      final firebaseUser = await remoteDataSource.getCurrentUser();
      
      if (firebaseUser == null) {
        return const Right(false);
      }
      
      final cachedToken = await localDataSource.getCachedToken();
      
      if (cachedToken == null || cachedToken.toEntity().isExpired) {
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
      final tokenModel = await localDataSource.getCachedToken();
      if (tokenModel != null) {
        return Right(tokenModel.toEntity());
      }
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
      final tokenModel = AuthTokenModel.fromEntity(token);
      await localDataSource.cacheToken(tokenModel);
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
      await localDataSource.clearAllCachedData();
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
        localDataSource.cacheUser(userModel);
        return userModel.toEntity();
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user) async {
    try {
      if (await networkInfo.isConnected) {
        final userModel = UserModel.fromEntity(user);
        final updatedUserModel = await remoteDataSource.updateUserProfile(userModel);
        await localDataSource.cacheUser(updatedUserModel);
        return Right(updatedUserModel.toEntity());
      } else {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
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
      if (await networkInfo.isConnected) {
        await remoteDataSource.resetPassword(email);
        return const Right(null);
      } else {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(failureMessage: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }
}