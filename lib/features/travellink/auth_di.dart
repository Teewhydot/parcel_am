import 'package:get_it/get_it.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth_usecase.dart';
import 'presentation/bloc/auth/auth_bloc.dart';

/// Dependency injection module for auth feature
class AuthDI {
  static void init() {
    final sl = GetIt.instance;

    // BLoC - Singleton since auth state should be shared across app
    sl.registerLazySingleton(
      () => AuthBloc(authUseCase: sl()),
    );

    // Use cases
    sl.registerLazySingleton(
      () => AuthUseCase(sl()),
    );

    // Repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
  }
}
