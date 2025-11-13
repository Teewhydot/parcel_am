import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId) async* {
    try {
      if (!await networkInfo.isConnected) {
        yield const Left(NoInternetFailure(failureMessage: 'No internet connection'));
        return;
      }

      await for (final messages in remoteDataSource.watchMessages(chatId)) {
        yield Right(messages.map((message) => message.toEntity()).toList());
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(MessageEntity message) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final messageModel = MessageModel.fromEntity(message);
      final sentMessage = await remoteDataSource.sendMessage(messageModel);
      return Right(sentMessage.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final updatedMessage = await remoteDataSource.updateMessage(chatId, messageId, updates);
      return Right(updatedMessage.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String chatId, String messageId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.deleteMessage(chatId, messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadFile(
    File file,
    String chatId,
    String fileName,
    String fileType,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final fileUrl = await remoteDataSource.uploadFile(file, chatId, fileName, fileType);
      return Right(fileUrl);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.updateMessageStatus(chatId, messageId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
