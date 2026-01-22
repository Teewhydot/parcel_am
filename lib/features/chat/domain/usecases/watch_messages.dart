import 'package:get_it/get_it.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class WatchMessages {
  final MessageRepository _repository;

  WatchMessages({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Stream<List<MessageEntity>> call(String chatId) {
    return _repository.watchMessages(chatId);
  }
}
