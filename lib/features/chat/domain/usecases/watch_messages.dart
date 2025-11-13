import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class WatchMessages {
  final MessageRepository repository;

  WatchMessages(this.repository);

  Stream<List<MessageEntity>> call(String chatId) {
    return repository.watchMessages(chatId);
  }
}
