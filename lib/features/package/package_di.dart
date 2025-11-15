import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/network_info.dart';
import 'data/datasources/package_remote_data_source.dart';
import 'data/repositories/package_repository_impl.dart';
import 'domain/repositories/package_repository.dart';
import 'domain/usecases/confirm_delivery.dart';
import 'domain/usecases/create_dispute.dart';
import 'domain/usecases/release_escrow.dart';
import 'domain/usecases/watch_active_packages.dart';
import 'domain/usecases/watch_package.dart';
import 'presentation/bloc/active_packages_bloc.dart';
import 'presentation/bloc/package_bloc.dart';

/// Dependency injection module for package feature
class PackageDI {
  static void init() {
    final sl = GetIt.instance;

    // BLoCs
    sl.registerFactory(() => ActivePackagesBloc(watchActivePackages: sl()));

    sl.registerFactory(
      () => PackageBloc(
        watchPackage: sl(),
        releaseEscrow: sl(),
        createDispute: sl(),
        confirmDelivery: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => WatchPackage(sl()));
    sl.registerLazySingleton(() => WatchActivePackages(sl()));
    sl.registerLazySingleton(() => ReleaseEscrow(sl()));
    sl.registerLazySingleton(() => CreateDispute(sl()));
    sl.registerLazySingleton(() => ConfirmDelivery(sl()));

    // Repositories
    sl.registerLazySingleton<PackageRepository>(
      () => PackageRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<PackageRemoteDataSource>(
      () => PackageRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
      ),
    );
  }
}
