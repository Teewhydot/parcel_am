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

// Feature modules no longer use DI - using direct instantiation instead

import 'features/travellink/data/datasources/auth_remote_data_source.dart';
import 'features/travellink/data/datasources/kyc_remote_data_source.dart' as travellink_kyc_ds;
import 'features/travellink/data/datasources/wallet_remote_data_source.dart' as travellink_wallet_ds;
import 'features/travellink/data/datasources/escrow_remote_data_source.dart';
import 'features/travellink/data/datasources/parcel_remote_data_source.dart';
import 'features/travellink/data/datasources/dashboard_remote_data_source.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';

import 'features/kyc/data/datasources/kyc_remote_datasource.dart' as kyc_ds;

import 'features/notifications/data/datasources/notification_remote_datasource.dart';

final sl = GetIt.instance;

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

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
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<NavigationService>(() => GetxNavigationService());

  //! Feature Modules (No longer using DI modules - direct instantiation)

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

  //! Features - Dashboard Data Sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(
      firestore: sl(),
      walletRemoteDataSource: sl<travellink_wallet_ds.WalletRemoteDataSource>(),
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
}
