import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parcel_am/core/utils/logger.dart';
import '../domain/repositories/presence_repository.dart';

/// Global presence service that manages user online/offline status
/// based on app lifecycle (foreground/background).
///
/// This service uses [WidgetsBindingObserver] to detect app state changes
/// and automatically updates the user's presence in Firestore.
class PresenceService with WidgetsBindingObserver {
  final PresenceRepository _repository;
  final FirebaseAuth _firebaseAuth;
  
  String? _currentUserId;
  StreamSubscription<User?>? _authSubscription;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Heartbeat interval to keep presence fresh (every 60 seconds)
  static const Duration _heartbeatInterval = Duration(seconds: 60);

  PresenceService({
    required PresenceRepository repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Get the current user ID
  String? get currentUserId => _currentUserId;

  /// Initialize the presence service and start observing app lifecycle.
  /// This should be called once in main.dart after the app starts.
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    // Listen to auth state changes to update presence accordingly
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        _setOnline();
        Logger.logBasic('Auth state: User ${user.uid} signed in, setting online', tag: 'PresenceService');
      } else {
        // User signed out, clean up
        if (_currentUserId != null) {
          _setOffline();
        }
        _currentUserId = null;
        _stopHeartbeat();
        Logger.logBasic('Auth state: User signed out', tag: 'PresenceService');
      }
    });

    // If user is already signed in, set online immediately
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _setOnline();
    }

    Logger.logSuccess('PresenceService initialized', tag: 'PresenceService');
  }

  /// Legacy initialize method for backwards compatibility
  @Deprecated('Use initialize() without userId parameter. Service now auto-detects user from FirebaseAuth.')
  void initializeWithUser(String userId) {
    _currentUserId = userId;
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
    _setOnline();
  }

  /// Dispose the service and stop observing
  void dispose() {
    if (!_isInitialized) return;

    _authSubscription?.cancel();
    _authSubscription = null;
    
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    
    // Set offline before disposing
    if (_currentUserId != null) {
      _setOffline();
    }
    
    _isInitialized = false;
    Logger.logBasic('PresenceService disposed', tag: 'PresenceService');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    Logger.logBasic('App lifecycle changed to: $state', tag: 'PresenceService');

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _setOnline();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, control center)
        // Keep online but don't do anything special
        break;
      case AppLifecycleState.paused:
        // App went to background
        _setOffline();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _setOffline();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (desktop/web)
        _setOffline();
        break;
    }
  }

  Future<void> _setOnline() async {
    if (_currentUserId == null) return;
    
    try {
      await _repository.setOnline(_currentUserId!);
      _startHeartbeat();
      Logger.logSuccess('User $_currentUserId set to online', tag: 'PresenceService');
    } catch (e) {
      Logger.logError('Failed to set online status: $e', tag: 'PresenceService');
    }
  }

  Future<void> _setOffline() async {
    if (_currentUserId == null) return;
    
    _stopHeartbeat();
    
    try {
      await _repository.setOffline(_currentUserId!);
      await _repository.updateLastSeen(_currentUserId!);
      Logger.logBasic('User $_currentUserId set to offline', tag: 'PresenceService');
    } catch (e) {
      Logger.logError('Failed to set offline status: $e', tag: 'PresenceService');
    }
  }

  /// Start periodic heartbeat to keep presence fresh
  void _startHeartbeat() {
    _stopHeartbeat(); // Ensure no duplicate timers

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_currentUserId != null) {
        try {
          await _repository.setOnline(_currentUserId!);
        } catch (e) {
          Logger.logError('Heartbeat failed: $e', tag: 'PresenceService');
        }
      }
    });
  }

  /// Stop the heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Manually set user as online (can be called from outside)
  Future<void> setOnline() => _setOnline();

  /// Manually set user as offline (can be called from outside)
  Future<void> setOffline() => _setOffline();

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    if (_currentUserId == null) return;
    await _repository.updateLastSeen(_currentUserId!);
  }

  /// Static helper to cleanup presence (e.g., on logout)
  static Future<void> cleanupPresence(
      FirebaseFirestore firestore, String userId) async {
    try {
      await firestore.collection('users').doc(userId).set({
        'presence': {
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      Logger.logError('Error cleaning up presence: $e', tag: 'PresenceService');
    }
  }
}
