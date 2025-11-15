import '../entities/chat.dart';
import '../../data/repositories/chat_repository_impl.dart';

class WatchUserChats {
  final repository = ChatRepositoryImpl();

  Stream<List<Chat>> call(String userId) {
    return repository.watchUserChats(userId);
  }
}
