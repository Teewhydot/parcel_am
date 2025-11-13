import 'package:equatable/equatable.dart';
import 'message.dart';

class Chat extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final Message? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, bool> isTyping;
  final Map<String, DateTime?> lastSeen;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isTyping,
    required this.lastSeen,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        participantIds,
        participantNames,
        participantAvatars,
        lastMessage,
        lastMessageTime,
        unreadCount,
        isTyping,
        lastSeen,
        createdAt,
      ];

  Chat copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    Message? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? isTyping,
    Map<String, DateTime?>? lastSeen,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
