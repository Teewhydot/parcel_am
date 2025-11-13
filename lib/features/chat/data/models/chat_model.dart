import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final Map<String, dynamic> participantInfo;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final String? chatType;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantInfo,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.chatType,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantInfo: data['participantInfo'] as Map<String, dynamic>? ?? {},
      lastMessage: data['lastMessage'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageAt: data['lastMessageAt'] is Timestamp
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCount: _parseUnreadCount(data['unreadCount']),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      chatType: data['chatType'] as String?,
    );
  }

  factory ChatModel.fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      participantIds: entity.participantIds,
      participantInfo: entity.participantInfo,
      lastMessage: entity.lastMessage,
      lastMessageSenderId: entity.lastMessageSenderId,
      lastMessageAt: entity.lastMessageAt,
      unreadCount: entity.unreadCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: entity.metadata,
      chatType: entity.chatType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'participantInfo': participantInfo,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'chatType': chatType,
    };
  }

  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      participantIds: participantIds,
      participantInfo: participantInfo,
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
      chatType: chatType,
    );
  }

  static Map<String, int> _parseUnreadCount(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, int>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
    }
    return {};
  }
}
