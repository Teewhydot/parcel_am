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
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/presence_repository_impl.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/services/presence_service.dart';
import 'features/chat/services/presence_rtdb_service.dart';

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

// TOTP 2FA Feature
import 'features/totp_2fa/data/datasources/totp_local_data_source.dart';
import 'features/totp_2fa/data/datasources/totp_remote_data_source.dart';
import 'features/totp_2fa/data/repositories/totp_repository_impl.dart';
import 'features/totp_2fa/domain/repositories/totp_repository.dart';

// KYC Feature
import 'features/kyc/data/datasources/kyc_remote_data_source.dart';
import 'features/kyc/data/repositories/kyc_repository_impl.dart';
import 'features/kyc/domain/repositories/kyc_repository.dart';

// Parcel AM Core Repositories
import 'features/parcel_am_core/data/repositories/auth_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/wallet_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/escrow_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/parcel_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/bank_account_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/withdrawal_repository_impl.dart';
import 'features/parcel_am_core/data/repositories/dashboard_repository_impl.dart';
import 'features/parcel_am_core/domain/repositories/auth_repository.dart';
import 'features/parcel_am_core/domain/repositories/wallet_repository.dart';
import 'features/parcel_am_core/domain/repositories/escrow_repository.dart';
import 'features/parcel_am_core/domain/repositories/parcel_repository.dart';
import 'features/parcel_am_core/domain/repositories/bank_account_repository.dart';
import 'features/parcel_am_core/domain/repositories/withdrawal_repository.dart';
import 'features/parcel_am_core/domain/repositories/dashboard_repository.dart';

// Parcel AM Core Data Sources (additional)
import 'features/parcel_am_core/data/datasources/bank_account_remote_data_source.dart';
import 'features/parcel_am_core/data/datasources/withdrawal_remote_data_source.dart';

// Chat Feature (additional)
import 'features/chat/data/datasources/message_remote_data_source.dart';
import 'features/chat/data/datasources/presence_remote_data_source.dart';
import 'features/chat/data/repositories/message_repository_impl.dart';
import 'features/chat/domain/repositories/message_repository.dart';

// Notifications Feature (additional)
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';

// Payments Feature (additional)
import 'features/payments/data/datasources/funding_order_remote_data_source.dart';
import 'features/payments/data/repositories/funding_order_repository_impl.dart';
import 'features/payments/domain/repositories/funding_order_repository.dart';

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

  // Connectivity and Offline Queue Services
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectionChecker: sl()),
  );
  sl.registerLazySingleton<OfflineQueueService>(
    () => OfflineQueueService(sl()),
  );

  // Presence System (RTDB-based for low latency)
  sl.registerLazySingleton<PresenceRtdbService>(
    () => PresenceRtdbService(),
  );
  sl.registerLazySingleton<PresenceRemoteDataSource>(
    () => PresenceRemoteDataSourceImpl(rtdbService: sl()),
  );
  sl.registerLazySingleton<PresenceRepository>(() => PresenceRepositoryImpl());
  sl.registerLazySingleton<PresenceService>(
    () => PresenceService(
      rtdbService: sl(),
      firebaseAuth: sl(),
    ),
  );

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


  //! Features - Chat Remote Data Source (RTDB-based for low latency)
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      storage: sl(),
    ),
  );

  //! Features - Chat Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(),
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
      settingsRepository: sl(),
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

  //! Features - TOTP 2FA
  // TOTP Data Sources
  sl.registerLazySingleton<TotpLocalDataSource>(
    () => TotpLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<TotpRemoteDataSource>(
    () => TotpRemoteDataSourceImpl(),
  );

  // TOTP Repository
  sl.registerLazySingleton<TotpRepository>(
    () => TotpRepositoryImpl(),
  );

  //! Features - KYC
  // KYC Data Source
  sl.registerLazySingleton<KycRemoteDataSource>(
    () => KycRemoteDataSourceImpl(),
  );

  // KYC Repository
  sl.registerLazySingleton<KycRepository>(
    () => KycRepositoryImpl(),
  );

  //! Features - Parcel AM Core Repositories
  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );

  // Wallet Repository
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(),
  );

  // Escrow Repository
  sl.registerLazySingleton<EscrowRepository>(
    () => EscrowRepositoryImpl(),
  );

  // Parcel Repository
  sl.registerLazySingleton<ParcelRepository>(
    () => ParcelRepositoryImpl(),
  );

  // Bank Account Data Source and Repository
  sl.registerLazySingleton<BankAccountRemoteDataSource>(
    () => BankAccountRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<BankAccountRepository>(
    () => BankAccountRepositoryImpl(),
  );

  // Withdrawal Data Source and Repository
  sl.registerLazySingleton<WithdrawalRemoteDataSource>(
    () => WithdrawalRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<WithdrawalRepository>(
    () => WithdrawalRepositoryImpl(),
  );

  // Dashboard Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(),
  );

  //! Features - Chat Additional Repositories
  // Message Data Source and Repository
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(),
  );

  //! Features - Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(),
  );

  //! Features - Funding Order
  sl.registerLazySingleton<FundingOrderRemoteDataSource>(
    () => FundingOrderRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FundingOrderRepository>(
    () => FundingOrderRepositoryImpl(),
  );
}
