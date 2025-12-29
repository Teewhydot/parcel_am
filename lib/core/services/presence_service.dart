import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/presence_repository.dart';
import '../utils/logger.dart';

class PresenceService with WidgetsBindingObserver {
  final PresenceRepository _repository;
  String? _currentUserId;

  PresenceService({required PresenceRepository repository})
      : _repository = repository;

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
    await _repository.setOnline(_currentUserId!);
  }

  Future<void> setOffline() async {
    if (_currentUserId == null) return;
    await _repository.setOffline(_currentUserId!);
  }

  Future<void> updateLastSeen() async {
    if (_currentUserId == null) return;
    await _repository.updateLastSeen(_currentUserId!);
  }

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
