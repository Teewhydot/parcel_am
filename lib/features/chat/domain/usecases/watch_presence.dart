import 'package:get_it/get_it.dart';
import '../entities/presence_entity.dart';
import '../repositories/message_repository.dart';

class WatchPresence {
  final MessageRepository _repository;

  WatchPresence({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Stream<PresenceEntity> call(String userId) {
    return _repository.watchPresence(userId);
  }
}
