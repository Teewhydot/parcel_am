import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<ChatEntity>>> watchUserChats(String userId) async* {
    try {
      if (!await networkInfo.isConnected) {
        yield const Left(NoInternetFailure(failureMessage: 'No internet connection'));
        return;
      }

      await for (final chats in remoteDataSource.watchUserChats(userId)) {
        yield Right(chats.map((chat) => chat.toEntity()).toList());
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, ChatEntity>> watchChat(String chatId) async* {
    try {
      if (!await networkInfo.isConnected) {
        yield const Left(NoInternetFailure(failureMessage: 'No internet connection'));
        return;
      }

      await for (final chat in remoteDataSource.watchChat(chatId)) {
        yield Right(chat.toEntity());
      }
    } catch (e) {
      yield Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createChat(
    List<String> participantIds,
    Map<String, dynamic> participantInfo,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final chat = await remoteDataSource.createChat(participantIds, participantInfo);
      return Right(chat.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.updateChat(chatId, updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat(String chatId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.deleteChat(chatId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(String chatId, String userId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      await remoteDataSource.markMessagesAsRead(chatId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatEntity?>> getChatByParticipants(List<String> participantIds) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }

      final chat = await remoteDataSource.getChatByParticipants(participantIds);
      return Right(chat?.toEntity());
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
