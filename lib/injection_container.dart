import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/services/navigation_service/nav_config.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_queue_service.dart';
import 'core/errors/failure_mapper.dart';
import 'core/errors/firebase_failure_mapper.dart';
import 'core/services/error/error_handler.dart';

// Chat Feature Module
import 'features/chat/domain/repositories/presence_repository.dart';
import 'features/chat/data/repositories/presence_repository_impl.dart';
import 'features/chat/services/presence_service.dart';

// Notifications Feature Module
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/domain/repositories/fcm_repository.dart';
import 'features/notifications/data/repositories/fcm_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_settings_repository.dart';
import 'features/notifications/data/repositories/notification_settings_repository_impl.dart';

// Payments Feature Module
import 'features/payments/services/endpoint_service.dart';
import 'features/payments/services/paystack_service.dart';

// Feature modules no longer use DI - using direct instantiation instead

import 'features/parcel_am_core/data/datasources/auth_remote_data_source.dart';
import 'features/parcel_am_core/data/datasources/wallet_remote_data_source.dart' as parcel_am_core_wallet_ds;
import 'features/parcel_am_core/data/datasources/escrow_remote_data_source.dart';
import 'features/parcel_am_core/data/datasources/parcel_remote_data_source.dart';
import 'features/parcel_am_core/data/datasources/dashboard_remote_data_source.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';

import 'features/notifications/data/datasources/notification_remote_datasource.dart';

// Payment System
import 'features/payments/data/remote/data_sources/paystack_payment_data_source.dart';
import 'features/payments/data/repositories/paystack_payment_repository_impl.dart';
import 'features/payments/domain/repositories/paystack_payment_repository.dart';
import 'features/payments/domain/use_cases/paystack_payment_usecase.dart';
import 'features/payments/presentation/manager/paystack_bloc/paystack_payment_bloc.dart';

// File Upload
import 'features/file_upload/data/remote/data_sources/file_upload.dart';
import 'features/file_upload/data/repositories/file_upload_repository_impl.dart';
import 'features/file_upload/domain/repositories/file_upload_repository.dart';
import 'features/file_upload/domain/use_cases/file_upload_usecase.dart';

// Passkey Authentication
import 'features/passkey/data/datasources/passkey_remote_data_source.dart';
import 'features/passkey/data/repositories/passkey_repository_impl.dart';
import 'features/passkey/domain/repositories/passkey_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External Services (Must be registered first)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);

  //! Core Services
  // Error Handling
  sl.registerLazySingleton<FailureMapper>(() => FirebaseFailureMapper());
  ErrorHandler.init(sl<FailureMapper>());

  sl.registerLazySingleton<NavigationService>(() => GetxNavigationService());

  // Connectivity and Offline Queue Services (Task Group 4.2.1)
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectionChecker: sl()),
  );
  sl.registerLazySingleton<OfflineQueueService>(
    () => OfflineQueueService(sl()),
  );

  // Presence System
  sl.registerLazySingleton<PresenceRepository>(() => PresenceRepositoryImpl(sl()));
  sl.registerLazySingleton<PresenceService>(() => PresenceService(repository: sl()));

  //! Feature Modules (No longer using DI modules - direct instantiation)

  //! Features - Auth Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => FirebaseRemoteDataSourceImpl(
  ));

  //! Features - Wallet (Parcel AM Core) Data Sources
  sl.registerLazySingleton<parcel_am_core_wallet_ds.WalletRemoteDataSource>(() => parcel_am_core_wallet_ds.WalletRemoteDataSourceImpl(
    firestore: sl(),
    connectivityService: sl(),
  ));

  //! Features - Escrow Data Sources
  sl.registerLazySingleton<EscrowRemoteDataSource>(() => EscrowRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Parcel Data Sources
  sl.registerLazySingleton<ParcelRemoteDataSource>(() => ParcelRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Dashboard Data Sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(
      firestore: sl(),
      walletRemoteDataSource: sl<parcel_am_core_wallet_ds.WalletRemoteDataSource>(),
    ),
  );

  //! Features - Notification Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: sl()),
  );


  //! Features - Chat Remote Data Source
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      firestore: sl(),
      storage: sl(),
    ),
  );

  //! Features - Payment System
  // Core Payment Services
  sl.registerLazySingleton<EndpointService>(() => EndpointService());
  sl.registerLazySingleton<PaystackService>(() => PaystackService(sl()));

  // Payment Data Sources
  sl.registerLazySingleton<PaystackPaymentDataSource>(
    () => FirebasePaystackPaymentDataSource(sl()),
  );

  // Payment Repositories
  sl.registerLazySingleton<PaystackPaymentRepository>(
    () => PaystackPaymentRepositoryImpl(),
  );

  // Payment Use Cases
  sl.registerLazySingleton<PaystackPaymentUseCase>(
    () => PaystackPaymentUseCase(),
  );

  // Payment BLoCs
  sl.registerFactory<PaystackPaymentBloc>(
    () => PaystackPaymentBloc(sl()),
  );

  //! Features - File Upload System
  // File Upload Data Sources
  sl.registerLazySingleton<FileUploadDataSource>(
    () => ImageKitFileUploadImpl(),
  );

  // File Upload Repositories
  sl.registerLazySingleton<FileUploadRepository>(
    () => FileUploadRepositoryImpl(),
  );

  // File Upload Use Cases
  sl.registerLazySingleton<FileUploadUseCase>(
    () => FileUploadUseCase(),
  );

  //! Notifications Feature Module
  // FCM Repository
  sl.registerLazySingleton<FCMRepository>(
    () => FCMRepositoryImpl(
      firebaseMessaging: sl(),
      firestore: sl(),
    ),
  );

  // Notification Settings Repository
  sl.registerLazySingleton<NotificationSettingsRepository>(
    () => NotificationSettingsRepositoryImpl(
      firestore: sl(),
    ),
  );

  // Notification Service
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService.getInstance(
      repository: sl(),
      localNotifications: sl(),
      remoteDataSource: sl(),
      navigationService: sl(),
      firebaseAuth: sl(),
    ),
  );

  //! Features - Passkey Authentication
  // Passkey Data Source
  sl.registerLazySingleton<PasskeyRemoteDataSource>(
    () => CorbadoPasskeyDataSourceImpl(),
  );

  // Passkey Repository
  sl.registerLazySingleton<PasskeyRepository>(
    () => PasskeyRepositoryImpl(),
  );
}
