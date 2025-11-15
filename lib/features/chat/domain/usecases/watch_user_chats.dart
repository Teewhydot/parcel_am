import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class WatchUserChats {
  final ChatRepository repository;

  WatchUserChats(this.repository);

  Stream<List<Chat>> call(String userId) {
    return repository.watchUserChats(userId);
  }
}
