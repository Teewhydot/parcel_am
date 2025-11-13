import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/user_entity.dart';

class ChatData extends Equatable {
  final List<ChatEntity> chats;
  final List<ChatUserEntity> searchResults;
  final String? filter;
  final String? currentUserId;

  const ChatData({
    this.chats = const [],
    this.searchResults = const [],
    this.filter,
    this.currentUserId,
  });

  ChatData copyWith({
    List<ChatEntity>? chats,
    List<ChatUserEntity>? searchResults,
    String? filter,
    String? currentUserId,
  }) {
    return ChatData(
      chats: chats ?? this.chats,
      searchResults: searchResults ?? this.searchResults,
      filter: filter ?? this.filter,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  List<ChatEntity> get filteredChats {
    if (filter == null || filter!.isEmpty) return chats;
    final lowerFilter = filter!.toLowerCase();
    return chats.where((chat) {
      return chat.participantName.toLowerCase().contains(lowerFilter) ||
          (chat.lastMessage?.toLowerCase().contains(lowerFilter) ?? false);
    }).toList();
  }

  @override
  List<Object?> get props => [chats, searchResults, filter, currentUserId];
}
