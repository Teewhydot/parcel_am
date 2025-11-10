import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../domain/exceptions/auth_exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<UserModel> signInWithPhoneNumber(String phoneNumber, String verificationCode);
  Future<void> sendPhoneVerificationCode(String phoneNumber);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> updateUserProfile(UserModel user);
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  String? _verificationId;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) {
        throw const UserNotFoundException();
      }

      return _mapFirebaseUserToModel(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const ServerException('Failed to create user');
      }

      await user.updateDisplayName(displayName);
      await user.reload();
      final updatedUser = firebaseAuth.currentUser;

      return _mapFirebaseUserToModel(updatedUser!);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithPhoneNumber(String phoneNumber, String verificationCode) async {
    try {
      if (_verificationId == null) {
        throw const PhoneAuthException('Verification ID not found. Please request verification code first.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: verificationCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        throw const UserNotFoundException();
      }

      return _mapFirebaseUserToModel(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      final completer = Completer<void>();
      
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await firebaseAuth.signInWithCredential(credential);
            completer.complete();
          } catch (e) {
            completer.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(_mapFirebaseAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return completer.future;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;
      
      return _mapFirebaseUserToModel(user);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return _mapFirebaseUserToModel(user);
    });
  }

  @override
  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const UserNotFoundException();
      }

      await firebaseUser.updateDisplayName(user.displayName);
      await firebaseUser.reload();
      
      final updatedUser = firebaseAuth.currentUser;
      return _mapFirebaseUserToModel(updatedUser!);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  UserModel _mapFirebaseUserToModel(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      isVerified: user.emailVerified,
      verificationStatus: user.emailVerified ? 'verified' : 'pending',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      additionalData: {},
      profilePhotoUrl: user.photoURL,
    );
  }

  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundException();
      case 'wrong-password':
        return const InvalidCredentialsException();
      case 'invalid-email':
        return const InvalidEmailException();
      case 'user-disabled':
        return const AuthException('User account has been disabled');
      case 'too-many-requests':
        return const AuthException('Too many requests. Please try again later');
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'invalid-verification-code':
        return const InvalidVerificationCodeException();
      case 'invalid-phone-number':
        return const InvalidPhoneNumberException();
      case 'session-expired':
        return const TokenExpiredException();
      default:
        return AuthException(e.message ?? 'Authentication failed');
    }
  }
}