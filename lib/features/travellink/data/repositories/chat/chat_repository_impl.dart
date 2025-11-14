import 'package:dartz/dartz.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/entities/chat/chat_entity.dart';
import '../../../domain/entities/chat/message_entity.dart';
import '../../../domain/entities/chat/presence_entity.dart';
import '../../../domain/repositories/chat/chat_repository.dart';
import '../../datasources/chat/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({ChatRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ChatRemoteDataSourceImpl();

  @override
  Stream<Either<Failure, List<ChatEntity>>> watchUserChats(String userId) async* {
    try {
      await for (final chats in _remoteDataSource.watchUserChats(userId)) {
        yield Right(chats);
      }
    } catch (error) {
      yield Left(ServerFailure(failureMessage: error.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId) async* {
    try {
      await for (final messages in _remoteDataSource.watchMessages(chatId)) {
        yield Right(messages);
      }
    } catch (error) {
      yield Left(ServerFailure(failureMessage: error.toString()));
    }
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
  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId) async* {
    try {
      await for (final presence in _remoteDataSource.watchUserPresence(userId)) {
        yield Right(presence);
      }
    } catch (error) {
      yield Left(ServerFailure(failureMessage: error.toString()));
    }
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
  Stream<Either<Failure, Map<String, bool>>> watchTypingStatus(String chatId) async* {
    try {
      await for (final typingStatus in _remoteDataSource.watchTypingStatus(chatId)) {
        yield Right(typingStatus);
      }
    } catch (error) {
      yield Left(ServerFailure(failureMessage: error.toString()));
    }
  }
}
