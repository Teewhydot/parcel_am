import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'presence_rtdb_service.dart';

/// Global presence service that manages user online/offline status
/// based on app lifecycle (foreground/background).
///
/// This service uses [WidgetsBindingObserver] to detect app state changes
/// and automatically updates the user's presence in RTDB.
///
/// Key features:
/// - Automatic offline detection via RTDB onDisconnect()
/// - Connection state monitoring with auto-reconnect handling
/// - Heartbeat to keep presence fresh
class PresenceService with WidgetsBindingObserver {
  final PresenceRtdbService _rtdbService;
  final FirebaseAuth _firebaseAuth;

  String? _currentUserId;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Heartbeat interval to keep presence fresh (every 60 seconds)
  static const Duration _heartbeatInterval = Duration(seconds: 60);

  PresenceService({
    PresenceRtdbService? rtdbService,
    FirebaseAuth? firebaseAuth,
  })  : _rtdbService = rtdbService ?? PresenceRtdbService(),
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
        _setupConnectionListener();
        Logger.logBasic(
          'Auth state: User ${user.uid} signed in, setting online',
          tag: 'PresenceService',
        );
      } else {
        // User signed out, clean up
        if (_currentUserId != null) {
          _setOffline();
        }
        _cancelConnectionListener();
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
      _setupConnectionListener();
    }

    Logger.logSuccess('PresenceService initialized (RTDB)', tag: 'PresenceService');
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
    _setupConnectionListener();
  }

  /// Dispose the service and stop observing
  void dispose() {
    if (!_isInitialized) return;

    _authSubscription?.cancel();
    _authSubscription = null;

    _cancelConnectionListener();
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
        // Set away status but don't go fully offline
        _setAway();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _setOffline();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        // Note: onDisconnect handler will take care of this automatically
        _setOffline();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (desktop/web)
        _setOffline();
        break;
    }
  }

  /// Set up connection state listener for auto-reconnect handling
  void _setupConnectionListener() {
    _cancelConnectionListener();

    if (_currentUserId == null) return;

    _connectionSubscription = _rtdbService.watchConnectionState().listen(
      (connected) {
        if (connected && _currentUserId != null) {
          Logger.logBasic(
            'RTDB connection restored, re-establishing presence',
            tag: 'PresenceService',
          );
          // Re-establish presence and onDisconnect handler
          _rtdbService.setOnline(_currentUserId!);
        }
      },
      onError: (error) {
        Logger.logError(
          'Connection state listener error: $error',
          tag: 'PresenceService',
        );
      },
    );
  }

  void _cancelConnectionListener() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }

  Future<void> _setOnline() async {
    if (_currentUserId == null) return;

    try {
      // setOnline also sets up onDisconnect handler automatically
      await _rtdbService.setOnline(_currentUserId!);
      _startHeartbeat();
      Logger.logSuccess(
        'User $_currentUserId set to online',
        tag: 'PresenceService',
      );
    } catch (e) {
      Logger.logError(
        'Failed to set online status: $e',
        tag: 'PresenceService',
      );
    }
  }

  Future<void> _setOffline() async {
    if (_currentUserId == null) return;

    _stopHeartbeat();

    try {
      await _rtdbService.setOffline(_currentUserId!);
      Logger.logBasic(
        'User $_currentUserId set to offline',
        tag: 'PresenceService',
      );
    } catch (e) {
      Logger.logError(
        'Failed to set offline status: $e',
        tag: 'PresenceService',
      );
    }
  }

  Future<void> _setAway() async {
    if (_currentUserId == null) return;

    try {
      await _rtdbService.setAway(_currentUserId!);
      Logger.logBasic(
        'User $_currentUserId set to away',
        tag: 'PresenceService',
      );
    } catch (e) {
      Logger.logError(
        'Failed to set away status: $e',
        tag: 'PresenceService',
      );
    }
  }

  /// Start periodic heartbeat to keep presence fresh
  void _startHeartbeat() {
    _stopHeartbeat(); // Ensure no duplicate timers

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_currentUserId != null) {
        try {
          // Refresh online status and onDisconnect handler
          await _rtdbService.setOnline(_currentUserId!);
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

  /// Manually set user as away (can be called from outside)
  Future<void> setAway() => _setAway();

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    if (_currentUserId == null) return;
    try {
      await _rtdbService.updateLastSeen(_currentUserId!);
    } catch (e) {
      Logger.logError(
        'Failed to update last seen: $e',
        tag: 'PresenceService',
      );
    }
  }

  /// Watch another user's presence
  Stream<PresenceData> watchUserPresence(String userId) {
    return _rtdbService.watchPresence(userId);
  }

  /// Check if a user is currently online
  Future<bool> isUserOnline(String userId) async {
    final presence = await _rtdbService.getPresence(userId);
    return presence?.isOnline ?? false;
  }

  /// Static helper to cleanup presence (e.g., on logout)
  /// This is now handled automatically by onDisconnect, but kept for explicit cleanup
  static Future<void> cleanupPresence(String userId) async {
    try {
      await PresenceRtdbService().setOffline(userId);
    } catch (e) {
      Logger.logError('Error cleaning up presence: $e', tag: 'PresenceService');
    }
  }
}
