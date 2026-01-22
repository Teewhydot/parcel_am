import 'package:get_it/get_it.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class WatchChat {
  final ChatRepository _repository;
  final String currentUserId;

  WatchChat({ChatRepository? repository, required this.currentUserId})
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Stream<ChatEntity> call(String chatId) {
    return _repository.watchChat(chatId).map((chat) {
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
