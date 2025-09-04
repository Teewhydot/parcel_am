import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  void setUser(UserModel user) {
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
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        email: email ?? _user!.email,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        additionalData: {..._user!.additionalData, ...?additionalData},
      );
      notifyListeners();
    }
  }

  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    _setLoading(true);
    _clearError();
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      _user = UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: phoneNumber,
        isVerified: false,
        verificationStatus: 'pending',
        createdAt: DateTime.now(),
        additionalData: {},
      );
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String otp) async {
    _setLoading(true);
    _clearError();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (otp == '123456') {
        _isAuthenticated = true;
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void signOut() {
    _user = null;
    _isAuthenticated = false;
    _clearError();
    notifyListeners();
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