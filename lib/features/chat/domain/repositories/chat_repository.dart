import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatEntity>> createChat(
    List<String> participantIds,
    Map<String, dynamic>? metadata,
  );

  Future<Either<Failure, ChatEntity>> getChat(String chatId);

  Future<Either<Failure, List<ChatEntity>>> getUserChats(String userId);

  Stream<ChatEntity> watchChat(String chatId);

  Stream<List<ChatEntity>> watchUserChats(String userId);
}
