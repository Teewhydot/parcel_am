import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class CreateChat {
  final ChatRepository repository;

  CreateChat(this.repository);

  Future<Either<Failure, ChatEntity>> call(CreateChatParams params) async {
    final result = await repository.createChat(params.participantIds);
    return result.fold(
      (failure) => Left(failure),
      (chat) {
        // Convert Chat to ChatEntity (simple 1-to-1 chat assumption)
        final otherUserId = chat.participantIds.firstWhere(
          (id) => id != params.participantIds.first,
          orElse: () => chat.participantIds.first,
        );
        return Right(ChatEntity(
          id: chat.id,
          participantId: otherUserId,
          participantName: chat.participantNames[otherUserId] ?? 'Unknown',
          participantAvatar: chat.participantAvatars[otherUserId],
          lastMessage: chat.lastMessage?.content,
          lastMessageTime: chat.lastMessageTime,
          unreadCount: chat.unreadCount[params.participantIds.first] ?? 0,
        ));
      },
    );
  }
}

class CreateChatParams extends Equatable {
  final List<String> participantIds;
  final Map<String, dynamic>? metadata;

  const CreateChatParams({
    required this.participantIds,
    this.metadata,
  });

  @override
  List<Object?> get props => [participantIds, metadata];
}
