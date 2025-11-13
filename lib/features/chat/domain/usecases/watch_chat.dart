import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class WatchChat {
  final ChatRepository repository;

  WatchChat(this.repository);

  Stream<ChatEntity> call(String chatId) {
    return repository.watchChat(chatId);
  }
}
