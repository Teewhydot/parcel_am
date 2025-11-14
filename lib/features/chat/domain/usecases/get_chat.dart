import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChat {
  final ChatRepository repository;
  final String currentUserId;

  GetChat(this.repository, this.currentUserId);

  Future<Either<Failure, ChatEntity>> call(String chatId) async {
    final result = await repository.getChat(chatId);
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
