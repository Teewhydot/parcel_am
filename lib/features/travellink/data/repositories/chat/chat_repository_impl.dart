import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/chat/chat_entity.dart';
import '../../../domain/entities/chat/message_entity.dart';
import '../../../domain/entities/chat/presence_entity.dart';
import '../../../domain/repositories/chat/chat_repository.dart';
import '../../datasources/chat/chat_remote_data_source.dart';
import '../../../../../core/services/error/error_handler.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({ChatRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ChatRemoteDataSourceImpl();

  @override
  Stream<Either<Failure, List<ChatEntity>>> watchUserChats(String userId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchUserChats(userId),
      operationName: 'watchUserChats',
    );
  }

  @override
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchMessages(chatId),
      operationName: 'watchMessages',
    );
  }

  @override
  Future<Either<Failure, ChatEntity>> createChat(
      List<String> participantIds) async {
    try {
      final chat = await _remoteDataSource.createChat(participantIds);
      return Right(chat);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  }) async {
    try {
      final message = await _remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        replyToId: replyToId,
      );
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await _remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String chatId, String userId) async {
    try {
      await _remoteDataSource.markAsRead(chatId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchUserPresence(userId),
      operationName: 'watchUserPresence',
    );
  }

  @override
  Future<Either<Failure, void>> updatePresence({
    required String userId,
    required OnlineStatus status,
    String? currentChatId,
  }) async {
    try {
      await _remoteDataSource.updatePresence(
        userId: userId,
        status: status,
        currentChatId: currentChatId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus({
    required String userId,
    required String chatId,
    required bool isTyping,
  }) async {
    try {
      await _remoteDataSource.setTypingStatus(
        userId: userId,
        chatId: chatId,
        isTyping: isTyping,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Map<String, bool>>> watchTypingStatus(String chatId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.watchTypingStatus(chatId),
      operationName: 'watchTypingStatus',
    );
  }
}
