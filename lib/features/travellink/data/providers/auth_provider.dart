import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../../../../core/services/firebase/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserEntity? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  void setUser(UserEntity user) {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void updateUserVerificationStatus(String status) {
    if (_user != null) {
      _user = _user!.copyWith(verificationStatus: status);
      notifyListeners();
    }
  }

  void updateUserProfile({
    String? displayName,
    String? email,
    Map<String, dynamic>? additionalData,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        email: email ?? _user!.email,
        additionalData: {..._user!.additionalData, ...?additionalData},
      );
      notifyListeners();
    }
  }

  Future<void> signInWithFirebaseUser(User firebaseUser, {String? displayName}) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Get or create user profile
      final userModel = UserModel(
        uid: firebaseUser.uid,
        displayName: displayName ?? firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        isVerified: firebaseUser.emailVerified,
        verificationStatus: firebaseUser.emailVerified ? 'verified' : 'pending',
        createdAt: DateTime.now(),
        additionalData: {},
      );
      _user = userModel.toEntity();
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Check if current user is authenticated
  void checkAuthState() {
    final firebaseUser = FirebaseService.instance.auth.currentUser;
    if (firebaseUser != null) {
      signInWithFirebaseUser(firebaseUser);
    } else {
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }
  
  // Listen to Firebase auth state changes
  void listenToAuthChanges() {
    FirebaseService.instance.auth.authStateChanges().listen((User? user) {
      if (user != null) {
        signInWithFirebaseUser(user);
      } else {
        _user = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> signOut() async {
    try {
      await FirebaseService.instance.auth.signOut();
      _user = null;
      _isAuthenticated = false;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}