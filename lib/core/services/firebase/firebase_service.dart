import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FirebaseEnvironment { development, production }

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService();
  
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseEnvironment _environment = kDebugMode 
      ? FirebaseEnvironment.development 
      : FirebaseEnvironment.production;

  // Use centralized Firebase configuration
  static String get testOtpCode => '123456'; // Default test OTP

  FirebaseService();

  FirebaseAuth get auth {
    if (_auth == null) {
      throw StateError('Firebase not initialized. Call initialize() first.');
    }
    return _auth!;
  }

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('Firebase not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Configure auth settings
      await _configureAuthSettings();

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      throw FirebaseInitializationException(
        'Failed to initialize Firebase: $e',
      );
    }
  }

  Future<void> _configureAuthSettings() async {
    if (_auth == null) return;

    // Set auth settings
    await _auth!.setSettings(
      appVerificationDisabledForTesting: _environment == FirebaseEnvironment.development,
    );

    // Configure language code for SMS
    _auth!.setLanguageCode('en');
  }

  void setEnvironment(FirebaseEnvironment environment) {
    _environment = environment;
  }

  String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check if it starts with 234 (Nigeria country code)
    if (digitsOnly.startsWith('234')) {
      return '+$digitsOnly';
    }
    
    // Check if it starts with 0 (local Nigerian format)
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      return '+234${digitsOnly.substring(1)}';
    }
    
    // Check if it's already in the correct format without +
    if (digitsOnly.length == 13 && digitsOnly.startsWith('234')) {
      return '+$digitsOnly';
    }
    
    // Check if it's just the number without country code or 0
    if (digitsOnly.length == 10) {
      return '+234$digitsOnly';
    }
    
    // Return as is if format is unclear
    return phoneNumber;
  }

  bool isValidNigerianNumber(String phoneNumber) {
    return _isValidNigerianNumber(phoneNumber);
  }

  bool isTestPhoneNumber(String phoneNumber) {
    return _isTestPhoneNumber(phoneNumber);
  }

  bool _isValidNigerianNumber(String phoneNumber) {
    // Nigerian phone numbers: +234XXXXXXXXXX or 0XXXXXXXXXX
    final regex = RegExp(r'^(\+234|0)[789]\d{9}$');
    return regex.hasMatch(phoneNumber);
  }

  bool _isTestPhoneNumber(String phoneNumber) {
    // Test phone numbers for development
    return phoneNumber == '+2349000000000' || phoneNumber == '09000000000';
  }

  Stream<User?> authStateChanges() {
    return auth.authStateChanges();
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}

class FirebaseInitializationException implements Exception {
  final String message;
  
  FirebaseInitializationException(this.message);
  
  @override
  String toString() => message;
}