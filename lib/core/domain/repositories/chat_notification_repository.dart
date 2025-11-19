import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatNotificationRepository {
  Stream<QuerySnapshot> watchUserChats(String userId);
  Future<Map<String, dynamic>?> getUserData(String userId);
}
