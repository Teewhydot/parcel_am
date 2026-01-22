import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChat {
  final ChatRepository _repository;
  final String currentUserId;

  GetChat({ChatRepository? repository, required this.currentUserId})
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Future<Either<Failure, ChatEntity>> call(String chatId) async {
    final result = await _repository.getChat(chatId);
    return result.fold(
      (failure) => Left(failure),
      (chat) {
        // Convert Chat to ChatEntity
        final otherUserId = chat.participantIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => chat.participantIds.first,
        );
        return Right(ChatEntity(
          id: chat.id,
          participantId: otherUserId,
          participantName: chat.participantNames[otherUserId] ?? 'Unknown',
          participantAvatar: chat.participantAvatars[otherUserId],
          lastMessage: chat.lastMessage?.content,
          lastMessageTime: chat.lastMessageTime,
          unreadCount: chat.unreadCount[currentUserId] ?? 0,
        ));
      },
    );
  }
}
