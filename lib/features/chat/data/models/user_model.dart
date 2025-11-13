import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class ChatUserModel extends ChatUserEntity {
  const ChatUserModel({
    required super.id,
    required super.name,
    super.avatar,
    super.email,
    super.isOnline,
  });

  factory ChatUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatUserModel(
      id: doc.id,
      name: data['displayName'] ?? data['name'] ?? 'Unknown',
      avatar: data['photoURL'] ?? data['avatar'],
      email: data['email'],
      isOnline: data['isOnline'] ?? false,
    );
  }
}
