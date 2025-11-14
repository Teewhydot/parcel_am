import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/chat_entity.dart';

class ChatData extends Equatable {
  final List<ChatEntity> chats;
  final String? currentUserId;
  final bool isListening;
  final String filter;

  const ChatData({
    this.chats = const [],
    this.currentUserId,
    this.isListening = false,
    this.filter = '',
  });

  /// Get filtered chats based on search filter
  List<ChatEntity> get filteredChats {
    if (filter.isEmpty) return chats;

    final lowerFilter = filter.toLowerCase();
    return chats.where((chat) {
      // For now, filter by participant IDs
      // In production, you'd filter by participant names
      return chat.participantIds.any((id) => id.toLowerCase().contains(lowerFilter)) ||
             (chat.lastMessage?.toLowerCase().contains(lowerFilter) ?? false);
    }).toList();
  }

  ChatData copyWith({
    List<ChatEntity>? chats,
    String? currentUserId,
    bool? isListening,
    String? filter,
  }) {
    return ChatData(
      chats: chats ?? this.chats,
      currentUserId: currentUserId ?? this.currentUserId,
      isListening: isListening ?? this.isListening,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [chats, currentUserId, isListening, filter];
}
