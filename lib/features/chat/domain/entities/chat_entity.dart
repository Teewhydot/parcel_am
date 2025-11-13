import 'package:equatable/equatable.dart';
import 'message_entity.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, dynamic> participantDetails;
  final MessageEntity? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  ChatEntity copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, dynamic>? participantDetails,
    MessageEntity? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        participantDetails,
        lastMessage,
        lastMessageTime,
        unreadCount,
        createdAt,
        updatedAt,
        metadata,
      ];
}
