import '../entities/presence_entity.dart';
import '../repositories/message_repository.dart';

class WatchPresence {
  final MessageRepository repository;

  WatchPresence(this.repository);

  Stream<PresenceEntity> call(String userId) {
    return repository.watchPresence(userId);
  }
}
