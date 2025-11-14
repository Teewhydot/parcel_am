import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class WatchChat {
  final ChatRepository repository;
  final String currentUserId;

  WatchChat(this.repository, this.currentUserId);

  Stream<ChatEntity> call(String chatId) {
    return repository.watchChat(chatId).map((chat) {
      final otherUserId = chat.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => chat.participantIds.first,
      );
      return ChatEntity(
        id: chat.id,
        participantId: otherUserId,
        participantName: chat.participantNames[otherUserId] ?? 'Unknown',
        participantAvatar: chat.participantAvatars[otherUserId],
        lastMessage: chat.lastMessage?.content,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: chat.unreadCount[currentUserId] ?? 0,
      );
    });
  }
}
