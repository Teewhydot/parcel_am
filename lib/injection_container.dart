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
import 'features/travellink/data/datasources/auth_local_data_source.dart';
import 'features/travellink/data/datasources/kyc_remote_data_source.dart';
import 'features/travellink/data/repositories/auth_repository_impl.dart';
import 'features/travellink/data/repositories/kyc_repository_impl.dart';
import 'features/travellink/domain/repositories/auth_repository.dart';
import 'features/travellink/domain/repositories/kyc_repository.dart';
import 'features/travellink/domain/usecases/login_usecase.dart';
import 'features/travellink/domain/usecases/register_usecase.dart';
import 'features/travellink/domain/usecases/logout_usecase.dart';
import 'features/travellink/domain/usecases/get_current_user_usecase.dart';
import 'features/travellink/domain/usecases/submit_kyc_usecase.dart';
import 'features/travellink/domain/usecases/get_kyc_status_usecase.dart';
import 'features/travellink/domain/usecases/watch_kyc_status_usecase.dart';
import 'features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'features/travellink/presentation/bloc/kyc/kyc_bloc.dart';

import 'features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart' as wallet_impl;
import 'features/wallet/domain/repositories/wallet_repository.dart' as wallet_repo;

import 'features/travellink/domain/repositories/wallet_repository.dart';
import 'features/travellink/domain/usecases/get_wallet_usecase.dart';
import 'features/travellink/domain/usecases/watch_balance_usecase.dart';
import 'features/travellink/domain/usecases/hold_balance_for_escrow_usecase.dart';
import 'features/travellink/domain/usecases/release_escrow_balance_usecase.dart';
import 'features/travellink/presentation/bloc/wallet/wallet_bloc.dart';

final sl = GetIt.instance;

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

Future<void> init() async {
  //! Features - Auth
  // BLoC
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    logoutUseCase: sl(),
    getCurrentUserUseCase: sl(),
    resetPasswordUseCase: sl(),
    watchKycStatusUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
    firebaseAuth: sl(),
    firestore: sl(),
  ));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(
    sharedPreferences: sl(),
  ));

  //! Features - KYC
  // BLoC
  sl.registerFactory(() => KycBloc(
    submitKycUseCase: sl(),
    getKycStatusUseCase: sl(),
    watchKycStatusUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => SubmitKycUseCase(sl()));
  sl.registerLazySingleton(() => GetKycStatusUseCase(sl()));
  sl.registerLazySingleton(() => WatchKycStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<KycRepository>(() => KycRepositoryImpl(
    remoteDataSource: sl(),
  ));

  // Data sources
  sl.registerLazySingleton<KycRemoteDataSource>(() => KycRemoteDataSourceImpl(
    firestore: sl(),
    storage: sl(),
  ));

  //! Features - Wallet (TravelLink)
  // BLoC
  sl.registerFactory(() => WalletBloc(
    getWalletUseCase: sl(),
    watchBalanceUseCase: sl(),
    holdBalanceForEscrowUseCase: sl(),
    releaseEscrowBalanceUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => GetWalletUseCase(sl()));
  sl.registerLazySingleton(() => WatchBalanceUseCase(sl()));
  sl.registerLazySingleton(() => HoldBalanceForEscrowUseCase(sl()));
  sl.registerLazySingleton(() => ReleaseEscrowBalanceUseCase(sl()));

  // Repository
  sl.registerLazySingleton<WalletRepository>(() => wallet_impl.WalletRepositoryImpl(
    remoteDataSource: sl(),
  ));

  // Data sources
  sl.registerLazySingleton<WalletRemoteDataSource>(() => WalletRemoteDataSourceImpl(
    firestore: sl(),
  ));

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<NavigationService>(() => GetxNavigationService());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}
