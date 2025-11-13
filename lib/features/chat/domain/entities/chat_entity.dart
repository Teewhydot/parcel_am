import 'package:equatable/equatable.dart';

enum PresenceStatus { online, offline, typing }

class ChatEntity extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final PresenceStatus presenceStatus;
  final DateTime? lastSeen;
  final bool isPinned;
  final bool isMuted;

  const ChatEntity({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.presenceStatus = PresenceStatus.offline,
    this.lastSeen,
    this.isPinned = false,
    this.isMuted = false,
  });

  ChatEntity copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    PresenceStatus? presenceStatus,
    DateTime? lastSeen,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      presenceStatus: presenceStatus ?? this.presenceStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantId,
        participantName,
        participantAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
        presenceStatus,
        lastSeen,
        isPinned,
        isMuted,
      ];
}
