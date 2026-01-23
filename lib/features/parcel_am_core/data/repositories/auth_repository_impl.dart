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
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    FlutterSecureStorage? secureStorage,
  })  : _remoteDataSource = remoteDataSource ?? GetIt.instance<AuthRemoteDataSource>(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return ErrorHandler.handle<UserEntity>(
      () => _remoteDataSource.signInWithEmailAndPassword(email, password),
    );
  }

  @override
  Stream<Either<Failure, UserModel>> watchUserData(String userId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchUserDetails(userId),
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
      () => _remoteDataSource.signUpWithEmailAndPassword(
        email,
        password,
        displayName,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return ErrorHandler.handle(() => _remoteDataSource.signOut());
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return ErrorHandler.handle<UserEntity?>(
      () => _remoteDataSource.getCurrentUser(),
    );
  }

  @override
  Future<Either<Failure, bool>> hasValidSession() async {
    return ErrorHandler.handle<bool>(
      () => _remoteDataSource.getCurrentUser().then((user) => user != null),
    );
  }

  @override
  Future<Either<Failure, AuthTokenEntity?>> getStoredToken() {
    return ErrorHandler.handle(
      () async {
        final tokenJson = await _secureStorage.read(key: _tokenKey);
        if (tokenJson == null) {
          return null;
        }
        final tokenMap = jsonDecode(tokenJson) as Map<String, dynamic>;
        return AuthTokenEntity.fromJson(tokenMap);
      },
      operationName: 'getStoredToken',
    );
  }

  @override
  Future<Either<Failure, void>> storeToken(AuthTokenEntity token) {
    return ErrorHandler.handle(
      () async {
        final tokenJson = jsonEncode(token.toJson());
        await _secureStorage.write(key: _tokenKey, value: tokenJson);
      },
      operationName: 'storeToken',
    );
  }

  @override
  Future<Either<Failure, void>> clearStoredData() async {
    return ErrorHandler.handle(() => _remoteDataSource.signOut());
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((userModel) {
      if (userModel != null) {
        return userModel.toEntity();
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(UserEntity user) async {
    return ErrorHandler.handle(
      () => _remoteDataSource.updateUserProfile(UserModel.fromEntity(user)),
    );
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    return ErrorHandler.handle(() => _remoteDataSource.resetPassword(email));
  }
}
