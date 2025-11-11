import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/exceptions/auth_exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> updateUserProfile(UserModel user);
  Future<void> resetPassword(String email);
  Future<void> syncKycStatus(String userId, String kycStatus);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore? firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    this.firestore,
  });

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

      return await _mapFirebaseUserToModelWithKyc(user);
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

      if (firestore != null && updatedUser != null) {
        await firestore!.collection('users').doc(updatedUser.uid).set({
          'uid': updatedUser.uid,
          'displayName': displayName,
          'email': email,
          'kycStatus': 'not_submitted',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return await _mapFirebaseUserToModelWithKyc(updatedUser!);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
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
      
      return await _mapFirebaseUserToModelWithKyc(user);
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
      return await _mapFirebaseUserToModelWithKyc(updatedUser!);
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

  Future<UserModel> _mapFirebaseUserToModelWithKyc(User user) async {
    String kycStatusString = 'not_submitted';

    if (firestore != null) {
      try {
        final userDoc = await firestore!.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          kycStatusString = userDoc.data()?['kycStatus'] ?? 'not_submitted';
        }
      } catch (e) {
        // Ignore errors and use default kycStatus
      }
    }

    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      isVerified: user.emailVerified,
      verificationStatus: user.emailVerified ? 'verified' : 'pending',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      additionalData: {},
      profilePhotoUrl: user.photoURL,
      kycStatus: KycStatus.fromString(kycStatusString),
    );
  }

  @override
  Future<void> syncKycStatus(String userId, String kycStatus) async {
    try {
      if (firestore == null) return;
      
      await firestore!.collection('users').doc(userId).update({
        'kycStatus': kycStatus,
      });
    } catch (e) {
      throw ServerException('Failed to sync KYC status: $e');
    }
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