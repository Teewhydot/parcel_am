import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parcel_am/features/parcel_am_core/domain/usecases/wallet_usecase.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';
import '../../domain/exceptions/auth_exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> updateUserProfile(UserModel user);
  Future<void> resetPassword(String email);
  Stream<UserModel> watchUserDetails(String userId);
}

class FirebaseRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final walletUseCase = WalletUseCase();  
  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) {
        throw const UserNotFoundException();
      }

      return await _mapFirebaseUserToModelWithKyc(user);
   
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {

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

      if (updatedUser != null) {
        await firestore.collection('users').doc(updatedUser.uid).set({
          'uid': updatedUser.uid,
          'displayName': displayName,
          'email': email,
          'kycStatus': 'not_submitted',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create wallet for new user with initial balance of 0
          try {
            await walletUseCase.createWallet(updatedUser.uid, initialBalance: 0.0);
          } catch (e) {
            // Log wallet creation error but don't fail signup
            Logger.logWarning('Failed to create wallet for user ${updatedUser.uid}: $e', tag: 'AuthDataSource');
          }
      }

      return await _mapFirebaseUserToModelWithKyc(updatedUser!);

  }

  @override
  Future<void> signOut() async {
    
      await firebaseAuth.signOut();
    
  }

  @override
  Future<UserModel?> getCurrentUser() async {
  
      final user = firebaseAuth.currentUser;
      if (user == null) return null;
     return await _mapFirebaseUserToModelWithKyc(user);
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
  
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const UserNotFoundException();
      }

      await firebaseUser.updateDisplayName(user.displayName);
      await firebaseUser.reload();
      
      final updatedUser = firebaseAuth.currentUser;
      return await _mapFirebaseUserToModelWithKyc(updatedUser!);
  
  }

  @override
  Future<void> resetPassword(String email) async {
  
      await firebaseAuth.sendPasswordResetEmail(email: email);
   
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

     final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          kycStatusString = userDoc.data()?['kycStatus'] ?? 'not_submitted';
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
  Stream<UserModel> watchUserDetails(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => _profileFromFirestore(doc));
  }

  UserModel _profileFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data['uid'],
      displayName: data['displayName'] ?? 'User',
      email: data['email'] ?? '',
      isVerified: firebaseAuth.currentUser?.emailVerified ?? false,
      verificationStatus: (firebaseAuth.currentUser?.emailVerified ?? false) ? 'verified' : 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalData: {},
      profilePhotoUrl: data['profilePhotoUrl'],
      kycStatus: KycStatus.fromString(data['kycStatus'] ?? 'not_submitted'),
    );
  }
}