import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../entities/user_entity.dart';

abstract class ChatRepository {
  Stream<Either<Failure, List<ChatEntity>>> getChatList(String userId);
  Stream<Either<Failure, PresenceStatus>> getPresenceStatus(String userId);
  Future<Either<Failure, void>> deleteChat(String chatId);
  Future<Either<Failure, void>> markAsRead(String chatId);
  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned);
  Future<Either<Failure, void>> toggleMute(String chatId, bool isMuted);
  Future<Either<Failure, List<ChatUserEntity>>> searchUsers(String query);
  Future<Either<Failure, String>> createChat(String currentUserId, String participantId);
}
