import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/network_info.dart';
import 'data/datasources/chat_remote_datasource.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/usecases/chat_usecase.dart';
import 'domain/usecases/watch_user_chats.dart';
import 'presentation/bloc/chat_bloc.dart';
import 'presentation/bloc/chats_list_bloc.dart';

/// Dependency injection module for chat feature
class ChatDI {
  static void init() {
    final sl = GetIt.instance;

    // BLoCs - factory to allow multiple instances
    sl.registerFactory(
      () => ChatBloc(chatUseCase: sl()),
    );

    sl.registerFactory(
      () => ChatsListBloc(watchUserChats: sl()),
    );

    // Use cases
    sl.registerLazySingleton(
      () => ChatUseCase(sl()),
    );

    sl.registerLazySingleton(
      () => WatchUserChats(sl()),
    );

    // Repositories
    sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
      ),
    );
  }
}
