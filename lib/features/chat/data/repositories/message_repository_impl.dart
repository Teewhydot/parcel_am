import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';
import '../datasources/presence_remote_data_source.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final PresenceRemoteDataSource _presenceDataSource;

  MessageRepositoryImpl({
    MessageRemoteDataSource? remoteDataSource,
    PresenceRemoteDataSource? presenceDataSource,
  })  : _remoteDataSource = remoteDataSource ?? GetIt.instance<MessageRemoteDataSource>(),
        _presenceDataSource = presenceDataSource ?? GetIt.instance<PresenceRemoteDataSource>();

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String senderId,
    String content,
    MessageType type,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
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

        final sentMessage = await _remoteDataSource.sendMessage(message);
        return sentMessage.toEntity();
      },
      operationName: 'sendMessage',
    );
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String chatId, {
    int? limit,
    String? startAfterMessageId,
  }) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        // Since watchMessages returns a stream, we'll take first value
        final messages = await _remoteDataSource.watchMessages(chatId).first;
        return messages.map((m) => m.toEntity()).toList();
      },
      operationName: 'getMessages',
    );
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _remoteDataSource
        .watchMessages(chatId)
        .map((messages) => messages.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String chatId,
    String userId,
    String messageId,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        await _remoteDataSource.updateMessageStatus(
          chatId,
          messageId,
          MessageStatus.read,
        );
      },
      operationName: 'markAsRead',
    );
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        // Extract chatId from messageId if needed, or modify datasource method
        // For now, assuming messageId contains enough info or datasource handles it
        final parts = messageId.split('/');
        final chatId = parts.length > 1 ? parts[0] : '';
        final actualMessageId = parts.length > 1 ? parts[1] : messageId;

        await _remoteDataSource.deleteMessage(chatId, actualMessageId);
      },
      operationName: 'deleteMessage',
    );
  }

  @override
  Future<Either<Failure, void>> updatePresence(
    String userId,
    bool isOnline,
    bool isTyping,
    String? typingInChatId,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        final status = isOnline ? PresenceStatus.online : PresenceStatus.offline;
        await _presenceDataSource.updatePresenceStatus(userId, status);

        if (isTyping) {
          await _presenceDataSource.updateTypingStatus(
            userId,
            typingInChatId,
            isTyping,
          );
        }
      },
      operationName: 'updatePresence',
    );
  }

  @override
  Stream<PresenceEntity> watchPresence(String userId) {
    return _presenceDataSource
        .watchUserPresence(userId)
        .map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> loadOlderMessages(
    String chatId, {
    int? beforePageNumber,
  }) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        final messages = await _remoteDataSource.loadOlderMessages(
          chatId,
          beforePageNumber: beforePageNumber,
        );
        return messages.map((m) => m.toEntity()).toList();
      },
      operationName: 'loadOlderMessages',
    );
  }

  @override
  Future<Either<Failure, bool>> hasOlderMessages(
    String chatId,
    int currentPageNumber,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NoInternetFailure(failureMessage: 'No internet connection');
        }

        return await _remoteDataSource.hasOlderMessages(
          chatId,
          currentPageNumber,
        );
      },
      operationName: 'hasOlderMessages',
    );
  }
}
