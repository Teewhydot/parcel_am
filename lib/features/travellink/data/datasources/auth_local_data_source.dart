import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';
import '../../domain/exceptions/auth_exceptions.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCachedUser();
  Future<AuthTokenModel?> getCachedToken();
  Future<void> cacheToken(AuthTokenModel token);
  Future<void> clearCachedToken();
  Future<void> clearAllCachedData();
  Future<bool> hasValidCachedSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _cachedUserKey = 'CACHED_USER';
  static const String _cachedTokenKey = 'CACHED_TOKEN';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = sharedPreferences.getString(_cachedUserKey);
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = json.encode(user.toJson());
      await sharedPreferences.setString(_cachedUserKey, jsonString);
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await sharedPreferences.remove(_cachedUserKey);
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<AuthTokenModel?> getCachedToken() async {
    try {
      final jsonString = sharedPreferences.getString(_cachedTokenKey);
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final token = AuthTokenModel.fromJson(jsonMap);
        
        if (token.isExpired) {
          await clearCachedToken();
          return null;
        }
        
        return token;
      }
      return null;
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheToken(AuthTokenModel token) async {
    try {
      final jsonString = json.encode(token.toJson());
      await sharedPreferences.setString(_cachedTokenKey, jsonString);
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<void> clearCachedToken() async {
    try {
      await sharedPreferences.remove(_cachedTokenKey);
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<void> clearAllCachedData() async {
    try {
      await Future.wait([
        clearCachedUser(),
        clearCachedToken(),
      ]);
    } catch (e) {
      throw const CacheException();
    }
  }

  @override
  Future<bool> hasValidCachedSession() async {
    try {
      final user = await getCachedUser();
      final token = await getCachedToken();
      
      return user != null && token != null && !token.isExpired;
    } catch (e) {
      return false;
    }
  }
}