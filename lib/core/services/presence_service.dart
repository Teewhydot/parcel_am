import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore;
  String? _currentUserId;

  PresenceService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  void initialize(String userId) {
    _currentUserId = userId;
    WidgetsBinding.instance.addObserver(this);
    setOnline();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setOffline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setOffline();
        break;
    }
  }

  Future<void> setOnline() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'presence.isOnline': true,
        'presence.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  Future<void> setOffline() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'presence.isOnline': false,
        'presence.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting offline status: $e');
    }
  }

  Future<void> updateLastSeen() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'presence.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last seen: $e');
    }
  }

  static Future<void> cleanupPresence(
      FirebaseFirestore firestore, String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'presence.isOnline': false,
        'presence.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error cleaning up presence: $e');
    }
  }
}
