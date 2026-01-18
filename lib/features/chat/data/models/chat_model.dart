import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat.dart';
import 'message_model.dart';

class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    required super.participantAvatars,
    super.lastMessage,
    super.lastMessageTime,
    required super.unreadCount,
    required super.isTyping,
    required super.lastSeen,
    required super.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String? ?? '',
      participantIds: json['participantIds'] != null
          ? List<String>.from(json['participantIds'] as List)
          : [],
      participantNames: json['participantNames'] != null
          ? Map<String, String>.from(json['participantNames'] as Map)
          : {},
      participantAvatars: json['participantAvatars'] != null
          ? Map<String, String?>.from(json['participantAvatars'] as Map)
          : {},
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: json['unreadCount'] != null
          ? Map<String, int>.from(json['unreadCount'] as Map)
          : {},
      isTyping: json['isTyping'] != null
          ? Map<String, bool>.from(json['isTyping'] as Map)
          : {},
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Map).map(
              (key, value) => MapEntry(
                key as String,
                value != null ? (value as Timestamp).toDate() : null,
              ),
            )
          : {},
      // Handle both Timestamp and null for createdAt
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return ChatModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage != null
          ? MessageModel.fromEntity(lastMessage!).toJson()
          : null,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'lastSeen': lastSeen.map(
        (key, value) =>
            MapEntry(key, value != null ? Timestamp.fromDate(value) : null),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
