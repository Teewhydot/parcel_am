import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<Message>>> getMessagesStream(String chatId) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(failureMessage: 'No internet connection'));
      return;
    }

    try {
      await for (final messages in remoteDataSource.getMessagesStream(chatId)) {
        yield Right(messages);
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(Message message) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final messageModel = MessageModel.fromEntity(message);
      await remoteDataSource.sendMessage(messageModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.updateMessageStatus(messageId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.markMessageAsRead(chatId, messageId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final url = await remoteDataSource.uploadMedia(
        filePath,
        chatId,
        type,
        onProgress,
      );
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.setTypingStatus(chatId, userId, isTyping);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastSeen(String chatId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.updateLastSeen(chatId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Chat>> getChatStream(String chatId) async* {
    if (!await networkInfo.isConnected) {
      yield const Left(NetworkFailure(failureMessage: 'No internet connection'));
      return;
    }

    try {
      await for (final chat in remoteDataSource.getChatStream(chatId)) {
        yield Right(chat);
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Chat>> createChat(List<String> participantIds) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final chat = await remoteDataSource.createChat(participantIds);
      return Right(chat);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Chat>> getChat(String chatId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final chat = await remoteDataSource.getChat(chatId);
      return Right(chat);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Chat>>> getUserChats(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(failureMessage: 'No internet connection'));
    }

    try {
      final chats = await remoteDataSource.getUserChats(userId);
      return Right(chats);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Chat> watchChat(String chatId) {
    return remoteDataSource.watchChat(chatId);
  }

  @override
  Stream<List<Chat>> watchUserChats(String userId) {
    return remoteDataSource.watchUserChats(userId);
  }
}
