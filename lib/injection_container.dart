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
import 'features/travellink/presentation/bloc/package/package_bloc.dart' as travellink_package;
import 'features/travellink/data/datasources/escrow_remote_data_source.dart';
import 'features/travellink/data/datasources/parcel_remote_data_source.dart';
import 'features/travellink/data/datasources/dashboard_remote_data_source.dart';

import 'features/travellink/data/repositories/escrow_repository_impl.dart';
import 'features/travellink/data/repositories/parcel_repository_impl.dart';
import 'features/travellink/data/repositories/kyc_repository_impl.dart';
import 'features/travellink/data/repositories/wallet_repository_impl.dart' as travellink_wallet_repo;
import 'features/travellink/data/repositories/dashboard_repository_impl.dart';

import 'features/travellink/domain/repositories/escrow_repository.dart';
import 'features/travellink/domain/repositories/parcel_repository.dart';
import 'features/travellink/domain/repositories/kyc_repository.dart';
import 'features/travellink/domain/repositories/wallet_repository.dart';
import 'features/travellink/domain/repositories/dashboard_repository.dart';

import 'features/travellink/domain/usecases/escrow_usecase.dart';
import 'features/travellink/domain/usecases/parcel_usecase.dart';
import 'features/travellink/domain/usecases/kyc_usecase.dart';
import 'features/travellink/domain/usecases/wallet_usecase.dart';
import 'features/travellink/domain/usecases/get_dashboard_metrics_usecase.dart';

import 'features/travellink/presentation/bloc/escrow/escrow_bloc.dart';
import 'features/travellink/presentation/bloc/parcel/parcel_bloc.dart';
import 'features/travellink/presentation/bloc/kyc/kyc_bloc.dart';
import 'features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import 'features/travellink/presentation/bloc/dashboard/dashboard_bloc.dart';

import 'features/kyc/data/datasources/kyc_remote_datasource.dart' as kyc_ds;

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

  //! Features - Escrow Repository
  sl.registerLazySingleton<EscrowRepository>(() => EscrowRepositoryImpl());

  //! Features - Parcel Repository
  sl.registerLazySingleton<ParcelRepository>(() => ParcelRepositoryImpl());

  //! Features - KYC Repository (TravelLink)
  sl.registerLazySingleton<KycRepository>(() => KycRepositoryImpl());

  //! Features - Wallet Repository (TravelLink)
  sl.registerLazySingleton<WalletRepository>(() => travellink_wallet_repo.WalletRepositoryImpl());

  //! Features - Dashboard Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  //! Features - Notification Repository
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl());

  //! Features - Escrow Use Cases
  sl.registerLazySingleton<EscrowUseCase>(() => EscrowUseCase());

  //! Features - Parcel Use Cases
  sl.registerLazySingleton<ParcelUseCase>(() => ParcelUseCase());

  //! Features - Notification Use Cases
  sl.registerLazySingleton<NotificationUseCase>(() => NotificationUseCase());

  //! Features - KYC Use Cases
  sl.registerLazySingleton<KycUseCase>(() => KycUseCase());

  //! Features - Wallet Use Cases
  sl.registerLazySingleton<WalletUseCase>(() => WalletUseCase());

  //! Features - Dashboard Use Cases
  sl.registerLazySingleton<GetDashboardMetricsUseCase>(
    () => GetDashboardMetricsUseCase(sl()),
  );

  //! Features - Escrow BLoC
  sl.registerFactory<EscrowBloc>(() => EscrowBloc());

  //! Features - Parcel BLoC
  sl.registerFactory<ParcelBloc>(() => ParcelBloc());

  //! Features - Package BLoC (TravelLink tracking)
  sl.registerFactory(() => travellink_package.PackageBloc());

  //! Features - KYC BLoC
  sl.registerFactory<KycBloc>(() => KycBloc());

  //! Features - Wallet BLoC
  sl.registerFactory<WalletBloc>(() => WalletBloc());

  //! Features - Dashboard BLoC
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(getDashboardMetricsUseCase: sl()),
  );

  //! Features - Notification BLoC
  sl.registerFactory<NotificationBloc>(() => NotificationBloc());

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
