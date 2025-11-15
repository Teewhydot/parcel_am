import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/network/network_info.dart';
import 'core/services/navigation_service/nav_config.dart';
import 'core/services/notification_service.dart';

import 'features/travellink/data/datasources/auth_remote_data_source.dart';
import 'features/travellink/data/datasources/kyc_remote_data_source.dart' as travellink_kyc_ds;
import 'features/travellink/data/datasources/wallet_remote_data_source.dart' as travellink_wallet_ds;
import 'features/travellink/data/datasources/escrow_remote_data_source.dart';
import 'features/travellink/data/datasources/parcel_remote_data_source.dart';

import 'features/travellink/data/repositories/escrow_repository_impl.dart';
import 'features/travellink/data/repositories/parcel_repository_impl.dart';

import 'features/travellink/domain/repositories/escrow_repository.dart';
import 'features/travellink/domain/repositories/parcel_repository.dart';

import 'features/travellink/domain/usecases/escrow_usecase.dart';
import 'features/travellink/domain/usecases/parcel_usecase.dart';

import 'features/travellink/presentation/bloc/escrow/escrow_bloc.dart';
import 'features/travellink/presentation/bloc/parcel/parcel_bloc.dart';
import 'features/travellink/presentation/bloc/wallet/wallet_bloc.dart';

import 'features/wallet/data/datasources/wallet_remote_datasource.dart';

import 'features/kyc/data/datasources/kyc_remote_datasource.dart' as kyc_ds;

import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/chat_usecase.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';

import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/notification_usecase.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

Future<void> init() async {
  //! Core Services
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<NavigationService>(() => GetxNavigationService());

  //! Features - Auth Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => FirebaseRemoteDataSourceImpl(
    firebaseAuth: sl(),
    firestore: sl(),
  ));

  //! Features - KYC (TravelLink) Data Sources
  sl.registerLazySingleton<travellink_kyc_ds.KycRemoteDataSource>(() => travellink_kyc_ds.KycRemoteDataSourceImpl(
    firestore: sl(),
    storage: sl(),
  ));

  //! Features - Wallet (TravelLink) Data Sources
  sl.registerLazySingleton<travellink_wallet_ds.WalletRemoteDataSource>(() => travellink_wallet_ds.WalletRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Wallet (Standalone) Data Sources
  sl.registerLazySingleton<WalletRemoteDataSource>(() => WalletRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - KYC (Standalone module) Data Sources
  sl.registerLazySingleton<kyc_ds.KycRemoteDataSource>(() => kyc_ds.KycRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Escrow Data Sources
  sl.registerLazySingleton<EscrowRemoteDataSource>(() => EscrowRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Parcel Data Sources
  sl.registerLazySingleton<ParcelRemoteDataSource>(() => ParcelRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Chat Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(() => ChatRemoteDataSourceImpl(
    firestore: sl(),
    storage: sl(),
  ));

  //! Features - Notification Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Escrow Repository
  sl.registerLazySingleton<EscrowRepository>(() => EscrowRepositoryImpl());

  //! Features - Parcel Repository
  sl.registerLazySingleton<ParcelRepository>(() => ParcelRepositoryImpl());

  //! Features - Chat Repository
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  //! Features - Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  //! Features - Escrow Use Cases
  sl.registerLazySingleton<EscrowUseCase>(() => EscrowUseCase(sl()));

  //! Features - Parcel Use Cases
  sl.registerLazySingleton<ParcelUseCase>(() => ParcelUseCase(sl()));

  //! Features - Chat Use Cases
  sl.registerLazySingleton<ChatUseCase>(() => ChatUseCase(sl()));

  //! Features - Notification Use Cases
  sl.registerLazySingleton<NotificationUseCase>(() => NotificationUseCase(sl()));

  //! Features - Escrow BLoC
  sl.registerFactory<EscrowBloc>(() => EscrowBloc(escrowUseCase: sl()));

  //! Features - Parcel BLoC
  sl.registerFactory<ParcelBloc>(() => ParcelBloc(parcelUseCase: sl()));

  //! Features - Wallet BLoC
  sl.registerFactory<WalletBloc>(() => WalletBloc());

  //! Features - Chat BLoC
  sl.registerFactory<ChatBloc>(() => ChatBloc(chatUseCase: sl()));

  //! Features - Notification BLoC
  sl.registerFactory<NotificationBloc>(() => NotificationBloc(notificationUseCase: sl()));

  //! Notification Service - Singleton
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService.getInstance(
      firebaseMessaging: sl(),
      localNotifications: sl(),
      remoteDataSource: sl(),
      navigationService: sl(),
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  //! External Services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}
