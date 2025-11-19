import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SessionManager {
  static const _storage = FlutterSecureStorage();
  
  // Keys for secure storage
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
  
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  
  SessionManager._();

  // Save user session after successful authentication
  Future<void> saveSession(User user) async {
    try {
      await _storage.write(key: _isLoggedInKey, value: 'true');
      await _storage.write(key: _userIdKey, value: user.uid);
      await _storage.write(key: _userEmailKey, value: user.email ?? '');
      await _storage.write(key: _userDisplayNameKey, value: user.displayName ?? '');
    } catch (e) {
      // Handle storage error
      debugPrint('Error saving session: $e');
    }
  }

  // Clear user session on logout
  Future<void> clearSession() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Handle storage error
      debugPrint('Error clearing session: $e');
    }
  }

  // Check if user has a valid session
  Future<bool> hasValidSession() async {
    try {
      final isLoggedIn = await _storage.read(key: _isLoggedInKey);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      // Session is valid if both stored flag is true and Firebase has current user
      return isLoggedIn == 'true' && firebaseUser != null;
    } catch (e) {
      // If there's any error, assume no valid session
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  // Get stored user data
  Future<Map<String, String?>> getStoredUserData() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      final userEmail = await _storage.read(key: _userEmailKey);
      final userDisplayName = await _storage.read(key: _userDisplayNameKey);
      
      return {
        'uid': userId,
        'email': userEmail,
        'displayName': userDisplayName,
      };
    } catch (e) {
      debugPrint('Error getting stored user data: $e');
      return {};
    }
  }

  // Update display name in storage
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _storage.write(key: _userDisplayNameKey, value: displayName);
    } catch (e) {
      debugPrint('Error updating display name: $e');
    }
  }

  // Initialize session on app start
  Future<bool> initializeSession() async {
    try {
      // Check if Firebase auth state is available
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null && await hasValidSession()) {
        // Update stored session with latest Firebase user data
        await saveSession(firebaseUser);
        return true;
      } else {
        // Clear any stale session data
        await clearSession();
        return false;
      }
    } catch (e) {
      debugPrint('Error initializing session: $e');
      await clearSession();
      return false;
    }
  }

  // Check if this is user's first time opening the app
  Future<bool> isFirstTimeUser() async {
    try {
      const firstTimeKey = 'is_first_time';
      final isFirstTime = await _storage.read(key: firstTimeKey);
      
      if (isFirstTime == null) {
        // Mark as not first time anymore
        await _storage.write(key: firstTimeKey, value: 'false');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return true; // Default to first time on error
    }
  }
}