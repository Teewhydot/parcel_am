import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<ChatEntity>>> getChatList(String userId) {
    return remoteDataSource.getChatList(userId).map((chats) {
      return Right(chats);
    }).handleError((error) {
      return Left(ServerFailure(failureMessage: error.toString()));
    });
  }

  @override
  Stream<Either<Failure, PresenceStatus>> getPresenceStatus(String userId) {
    return remoteDataSource.getPresenceStatus(userId).map((status) {
      return Right(status);
    }).handleError((error) {
      return Left(ServerFailure(failureMessage: error.toString()));
    });
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
  Future<Either<Failure, void>> markAsRead(String chatId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
      await remoteDataSource.markAsRead(chatId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
      await remoteDataSource.togglePin(chatId, isPinned);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMute(String chatId, bool isMuted) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
      await remoteDataSource.toggleMute(chatId, isMuted);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatUserEntity>>> searchUsers(String query) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createChat(String currentUserId, String participantId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NoInternetFailure(failureMessage: 'No internet connection'));
      }
      final chatId = await remoteDataSource.createChat(currentUserId, participantId);
      return Right(chatId);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }
}
