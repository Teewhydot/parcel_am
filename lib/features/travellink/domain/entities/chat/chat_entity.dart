import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCounts = const {},
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  ChatEntity copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        lastMessage,
        lastMessageTime,
        lastMessageSenderId,
        unreadCounts,
        createdAt,
        updatedAt,
        metadata,
      ];
}
