import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({ChatRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GetIt.instance<ChatRemoteDataSource>();

  @override
  Stream<Either<Failure, List<Message>>> getMessagesStream(String chatId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.getMessagesStream(chatId),
      operationName: 'getMessagesStream',
    );
  }

  @override
  Future<Either<Failure, void>> sendMessage(Message message) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        final messageModel = MessageModel.fromEntity(message);
        await _remoteDataSource.sendMessage(messageModel);
      },
      operationName: 'sendMessage',
    );
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        await _remoteDataSource.updateMessageStatus(messageId, status);
      },
      operationName: 'updateMessageStatus',
    );
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        await _remoteDataSource.markMessageAsRead(chatId, messageId, userId);
      },
      operationName: 'markMessageAsRead',
    );
  }

  @override
  Future<Either<Failure, String>> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        return await _remoteDataSource.uploadMedia(
          filePath,
          chatId,
          type,
          onProgress,
        );
      },
      operationName: 'uploadMedia',
    );
  }

  @override
  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        await _remoteDataSource.setTypingStatus(chatId, userId, isTyping);
      },
      operationName: 'setTypingStatus',
    );
  }

  @override
  Future<Either<Failure, void>> updateLastSeen(String chatId, String userId) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        await _remoteDataSource.updateLastSeen(chatId, userId);
      },
      operationName: 'updateLastSeen',
    );
  }

  @override
  Stream<Either<Failure, Chat>> getChatStream(String chatId) {
    return ErrorHandler.handleStream(
      () => _remoteDataSource.getChatStream(chatId),
      operationName: 'getChatStream',
    );
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        await _remoteDataSource.deleteMessage(messageId);
      },
      operationName: 'deleteMessage',
    );
  }

  @override
  Future<Either<Failure, Chat>> createChat(List<String> participantIds) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        return await _remoteDataSource.createChat(participantIds);
      },
      operationName: 'createChat',
    );
  }

  @override
  Future<Either<Failure, Chat>> getChat(String chatId) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        return await _remoteDataSource.getChat(chatId);
      },
      operationName: 'getChat',
    );
  }

  @override
  Future<Either<Failure, List<Chat>>> getUserChats(String userId) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        return await _remoteDataSource.getUserChats(userId);
      },
      operationName: 'getUserChats',
    );
  }

  @override
  Stream<Chat> watchChat(String chatId) {
    return _remoteDataSource.watchChat(chatId);
  }

  @override
  Stream<List<Chat>> watchUserChats(String userId) {
    return _remoteDataSource.watchUserChats(userId);
  }

  @override
  Future<Either<Failure, Chat>> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) {
    return ErrorHandler.handle(
      () async {
        if (!await InternetConnectionChecker.instance.hasConnection) {
          throw const NetworkFailure(failureMessage: 'No internet connection');
        }
        return await _remoteDataSource.getOrCreateChat(
          chatId: chatId,
          participantIds: participantIds,
          participantNames: participantNames,
        );
      },
      operationName: 'getOrCreateChat',
    );
  }

  @override
  Future<void> markMessageNotificationSent(String chatId, String messageId) async {
    await _remoteDataSource.markMessageNotificationSent(chatId, messageId);
  }

  @override
  Future<bool> tryClaimNotification(String chatId, String messageId) async {
    return _remoteDataSource.tryClaimNotification(chatId, messageId);
  }
}
