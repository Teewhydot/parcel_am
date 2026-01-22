import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:parcel_am/core/utils/logger.dart';
import '../../domain/repositories/presence_repository.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  final FirebaseFirestore _firestore;

  PresenceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? GetIt.instance<FirebaseFirestore>();

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
      Logger.logError('Error setting online status: $e', tag: 'PresenceRepository');
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
      Logger.logError('Error setting offline status: $e', tag: 'PresenceRepository');
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
      Logger.logError('Error updating last seen: $e', tag: 'PresenceRepository');
      rethrow;
    }
  }
}
