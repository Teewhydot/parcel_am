import 'package:get_it/get_it.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class WatchUserChats {
  final ChatRepository _repository;

  WatchUserChats({ChatRepository? repository})
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Stream<List<Chat>> call(String userId) {
    return _repository.watchUserChats(userId);
  }
}
