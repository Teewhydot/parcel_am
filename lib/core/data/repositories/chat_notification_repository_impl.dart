import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/chat_notification_repository.dart';
import '../../utils/logger.dart';

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
      Logger.logError('Firestore Error (ChatNotifications): $error', tag: 'ChatNotificationRepositoryImpl');
      if (error.toString().contains('index')) {
        Logger.logWarning('INDEX REQUIRED: Create a composite index for:\n   Collection: chats\n   Fields: participants (Array), [add other indexed fields]\n   Or visit the Firebase Console to create the index automatically.', tag: 'ChatNotificationRepositoryImpl');
      }
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data();
    } catch (e) {
      Logger.logError('Error fetching user data: $e', tag: 'ChatNotificationRepositoryImpl');
      return null;
    }
  }
}
