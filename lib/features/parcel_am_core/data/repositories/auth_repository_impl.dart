import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return ErrorHandler.handle<UserEntity>(
      () => remoteDataSource.signInWithEmailAndPassword(email, password),
    );
  }

  @override
  Stream<Either<Failure, UserModel>> watchUserData(String userId) {
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
    return ErrorHandler.handle<UserEntity>(
      () => remoteDataSource.signUpWithEmailAndPassword(
        email,
        password,
        displayName,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return ErrorHandler.handle(() => remoteDataSource.signOut());
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return ErrorHandler.handle<UserEntity?>(
      () => remoteDataSource.getCurrentUser(),
    );
  }

  @override
  Future<Either<Failure, bool>> hasValidSession() async {
    return ErrorHandler.handle<bool>(
      () => remoteDataSource.getCurrentUser().then((user) => user != null),
    );
  }

  @override
  Future<Either<Failure, AuthTokenEntity?>> getStoredToken() async {
    try {
      final tokenJson = await _secureStorage.read(key: _tokenKey);
      if (tokenJson == null) {
        return const Right(null);
      }
      final tokenMap = jsonDecode(tokenJson) as Map<String, dynamic>;
      return Right(AuthTokenEntity.fromJson(tokenMap));
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> storeToken(AuthTokenEntity token) async {
    try {
      final tokenJson = jsonEncode(token.toJson());
      await _secureStorage.write(key: _tokenKey, value: tokenJson);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(failureMessage: e.message));
    } catch (e) {
      return Left(UnknownFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearStoredData() async {
    return ErrorHandler.handle(() => remoteDataSource.signOut());
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
  Future<Either<Failure, void>> updateUserProfile(UserEntity user) async {
    return ErrorHandler.handle(
      () => remoteDataSource.updateUserProfile(UserModel.fromEntity(user)),
    );
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    return ErrorHandler.handle(() => remoteDataSource.resetPassword(email));
  }
}
