import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participantId,
    required super.participantName,
    super.participantAvatar,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount,
    super.presenceStatus,
    super.lastSeen,
    super.isPinned,
    super.isMuted,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? 'Unknown',
      participantAvatar: data['participantAvatar'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: data['unreadCount'] ?? 0,
      presenceStatus: _presenceFromString(data['presenceStatus']),
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'presenceStatus': presenceStatus.toString().split('.').last,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }

  static PresenceStatus _presenceFromString(String? status) {
    switch (status) {
      case 'online':
        return PresenceStatus.online;
      case 'typing':
        return PresenceStatus.typing;
      default:
        return PresenceStatus.offline;
    }
  }
}
