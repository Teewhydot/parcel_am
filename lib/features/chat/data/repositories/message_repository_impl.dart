import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';
import '../datasources/presence_remote_data_source.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final PresenceRemoteDataSource presenceDataSource;

  MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.presenceDataSource,
  });

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String senderId,
    String content,
    MessageType type,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: metadata?['senderName'] as String? ?? '',
        senderAvatar: metadata?['senderAvatar'] as String?,
        content: content,
        type: type,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        mediaUrl: metadata?['mediaUrl'] as String?,
        thumbnailUrl: metadata?['thumbnailUrl'] as String?,
        fileName: metadata?['fileName'] as String?,
        fileSize: metadata?['fileSize'] as int?,
      );

      final sentMessage = await remoteDataSource.sendMessage(message);
      return Right(sentMessage.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String chatId, {
    int? limit,
    String? startAfterMessageId,
  }) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      // Since watchMessages returns a stream, we'll take first value
      final messages = await remoteDataSource.watchMessages(chatId).first;
      return Right(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return remoteDataSource
        .watchMessages(chatId)
        .map((messages) => messages.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String chatId,
    String userId,
    String messageId,
  ) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      await remoteDataSource.updateMessageStatus(
        chatId,
        messageId,
        MessageStatus.read,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      // Extract chatId from messageId if needed, or modify datasource method
      // For now, assuming messageId contains enough info or datasource handles it
      final parts = messageId.split('/');
      final chatId = parts.length > 1 ? parts[0] : '';
      final actualMessageId = parts.length > 1 ? parts[1] : messageId;

      await remoteDataSource.deleteMessage(chatId, actualMessageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePresence(
    String userId,
    bool isOnline,
    bool isTyping,
    String? typingInChatId,
  ) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      final status = isOnline ? PresenceStatus.online : PresenceStatus.offline;
      await presenceDataSource.updatePresenceStatus(userId, status);

      if (isTyping) {
        await presenceDataSource.updateTypingStatus(
          userId,
          typingInChatId,
          isTyping,
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<PresenceEntity> watchPresence(String userId) {
    return presenceDataSource
        .watchUserPresence(userId)
        .map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> loadOlderMessages(
    String chatId, {
    int? beforePageNumber,
  }) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      final messages = await remoteDataSource.loadOlderMessages(
        chatId,
        beforePageNumber: beforePageNumber,
      );
      return Right(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasOlderMessages(
    String chatId,
    int currentPageNumber,
  ) async {
    try {
      if (!await InternetConnectionChecker.instance.hasConnection) {
        return const Left(
          NoInternetFailure(failureMessage: 'No internet connection'),
        );
      }

      final hasMore = await remoteDataSource.hasOlderMessages(
        chatId,
        currentPageNumber,
      );
      return Right(hasMore);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
