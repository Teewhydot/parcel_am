import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/presence_repository.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  final FirebaseFirestore _firestore;

  PresenceRepositoryImpl(this._firestore);

  @override
  Future<void> setOnline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'presence': {
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting online status: $e');
      rethrow;
    }
  }

  @override
  Future<void> setOffline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'presence': {
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting offline status: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'presence': {
          'lastSeen': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating last seen: $e');
      rethrow;
    }
  }
}
