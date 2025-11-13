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
import 'features/chat/data/datasources/message_remote_data_source.dart';
import 'features/chat/data/datasources/presence_remote_data_source.dart';

import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/data/repositories/message_repository_impl.dart';
import 'features/chat/data/repositories/presence_repository_impl.dart';

import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/repositories/message_repository.dart';
import 'features/chat/domain/repositories/presence_repository.dart';

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
  ));

  sl.registerLazySingleton<MessageRemoteDataSource>(() => MessageRemoteDataSourceImpl(
    firestore: sl(),
    storage: sl(),
  ));

  sl.registerLazySingleton<PresenceRemoteDataSource>(() => PresenceRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Features - Escrow Repository
  sl.registerLazySingleton<EscrowRepository>(() => EscrowRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  //! Features - Parcel Repository
  sl.registerLazySingleton<ParcelRepository>(() => ParcelRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  //! Features - Chat Repositories
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  sl.registerLazySingleton<MessageRepository>(() => MessageRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  sl.registerLazySingleton<PresenceRepository>(() => PresenceRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  //! Features - Escrow Use Cases
  sl.registerLazySingleton<EscrowUseCase>(() => EscrowUseCase(sl()));

  //! Features - Parcel Use Cases
  sl.registerLazySingleton<ParcelUseCase>(() => ParcelUseCase(sl()));

  //! Features - Escrow BLoC
  sl.registerFactory<EscrowBloc>(() => EscrowBloc(escrowUseCase: sl()));

  //! Features - Parcel BLoC
  sl.registerFactory<ParcelBloc>(() => ParcelBloc(parcelUseCase: sl()));

  //! Features - Wallet BLoC
  sl.registerFactory<WalletBloc>(() => WalletBloc());

  //! External Services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}
