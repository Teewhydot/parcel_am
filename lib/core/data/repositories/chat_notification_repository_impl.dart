import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/chat_notification_repository.dart';

class ChatNotificationRepositoryImpl implements ChatNotificationRepository {
  final FirebaseFirestore _firestore;

  ChatNotificationRepositoryImpl(this._firestore);

  @override
  Stream<QuerySnapshot> watchUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .handleError((error) {
      debugPrint('❌ Firestore Error (ChatNotifications): $error');
      if (error.toString().contains('index')) {
        debugPrint('🔍 INDEX REQUIRED: Create a composite index for:');
        debugPrint('   Collection: chats');
        debugPrint('   Fields: participants (Array), [add other indexed fields]');
        debugPrint('   Or visit the Firebase Console to create the index automatically.');
      }
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }
}
