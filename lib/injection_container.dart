import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'core/network/network_info.dart';
import 'core/services/navigation_service/nav_config.dart';

import 'features/travellink/data/datasources/auth_remote_data_source.dart';
import 'features/travellink/data/datasources/kyc_remote_data_source.dart' as travellink_kyc_ds;
import 'features/travellink/data/datasources/wallet_remote_data_source.dart' as travellink_wallet_ds;

import 'features/wallet/data/datasources/wallet_remote_datasource.dart';

import 'features/kyc/data/datasources/kyc_remote_datasource.dart' as kyc_ds;

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

  //! External Services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}
