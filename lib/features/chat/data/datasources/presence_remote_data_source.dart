import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/presence_model.dart';
import '../../domain/entities/presence_entity.dart';
import '../../../../core/utils/logger.dart';

abstract class PresenceRemoteDataSource {
  Stream<PresenceModel> watchUserPresence(String userId);
  Future<void> updatePresenceStatus(String userId, PresenceStatus status);
  Future<void> updateTypingStatus(String userId, String? chatId, bool isTyping);
  Future<void> updateLastSeen(String userId);
  Future<PresenceModel?> getUserPresence(String userId);
}

class PresenceRemoteDataSourceImpl implements PresenceRemoteDataSource {
  final FirebaseFirestore firestore;

  PresenceRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<PresenceModel> watchUserPresence(String userId) {
    return firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchUserPresence): $error', tag: 'PresenceDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'PresenceDataSource');
      }
    })
        .map((snapshot) {
      if (!snapshot.exists) {
        return PresenceModel(
          userId: userId,
          status: PresenceStatus.offline,
          lastSeen: DateTime.now(),
        );
      }
      return PresenceModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<void> updatePresenceStatus(String userId, PresenceStatus status) async {
    final now = DateTime.now();
    await firestore.collection('presence').doc(userId).set({
      'status': status.name,
      'lastSeen': status == PresenceStatus.offline ? Timestamp.fromDate(now) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateTypingStatus(String userId, String? chatId, bool isTyping) async {
    await firestore.collection('presence').doc(userId).set({
      'isTyping': isTyping,
      'typingInChatId': isTyping ? chatId : null,
      'lastTypingAt': isTyping ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    await firestore.collection('presence').doc(userId).set({
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<PresenceModel?> getUserPresence(String userId) async {
    final doc = await firestore.collection('presence').doc(userId).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return PresenceModel.fromFirestore(doc);
  }
}
