import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetUserChats {
  final ChatRepository repository;

  GetUserChats(this.repository);

  Future<Either<Failure, List<ChatEntity>>> call(String userId) async {
    final result = await repository.getUserChats(userId);
    return result.fold(
      (failure) => Left(failure),
      (chats) {
        // Convert List<Chat> to List<ChatEntity>
        final chatEntities = chats.map((chat) {
          final otherUserId = chat.participantIds.firstWhere(
            (id) => id != userId,
            orElse: () => chat.participantIds.first,
          );
          return ChatEntity(
            id: chat.id,
            participantId: otherUserId,
            participantName: chat.participantNames[otherUserId] ?? 'Unknown',
            participantAvatar: chat.participantAvatars[otherUserId],
            lastMessage: chat.lastMessage?.content,
            lastMessageTime: chat.lastMessageTime,
            unreadCount: chat.unreadCount[userId] ?? 0,
          );
        }).toList();
        return Right(chatEntities);
      },
    );
  }
}
