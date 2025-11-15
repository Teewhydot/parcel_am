## Parcel AM — Copilot instructions (concise)

This file gives targeted, actionable guidance for AI coding agents working on this repo.
Keep suggestions small, self-contained, and reference concrete files below.

- Project type: Flutter app (Dart) using Clean-architecture + BLoC patterns.
- Key entry points: `lib/main.dart` (app bootstrap) and `lib/injection_container.dart` (GetIt DI `sl`).

What matters most
- Dependency injection: `sl` is the global GetIt instance (see `lib/injection_container.dart`).
  - When adding a service/repository/usecase/bloc, register it in `init()` here.
  - Example: `sl.registerFactory(() => AuthBloc(...))` and `sl.registerLazySingleton(() => LoginUseCase(sl()));`

- Feature layout: each feature follows the folder pattern under `lib/features/<feature>/`:
  - `data/` (datasources, repositories, models)
  - `domain/` (entities, repositories interfaces, usecases)
  - `presentation/` (BLoCs, UI)
  - Example: `features/travellink/data/datasources/auth_remote_data_source.dart`.

- BLoC & lifecycle: project uses a custom BlocManager system for lifecycle, persistence and cross-BLoC comms.
  - Read `lib/core/bloc_manager/README.md` and `lib/core/bloc/README.md` for patterns and examples.
  - Prefer `BlocManager<T,S>` when a BLoC needs state persistence or cross-BLoC messaging.

- App init and Firebase: `AppConfig.init()` is called in `main()` (see `lib/main.dart`).
  - Initialization errors are surfaced to a `FirebaseErrorApp` (main shows how to handle failures).

Developer workflows (commands to run)
- Install dependencies: `flutter pub get` (or `dart pub get`).
- Run app: `flutter run -d <device>` (iOS: open Xcode if dealing with signing). The project contains platform folders (`android/`, `ios/`, `web/`, `windows/`).
- Tests: `flutter test` (unit/widget). Mocks and generated files: `flutter pub run build_runner build --delete-conflicting-outputs`.

Testing and CI notes
- Tests use `mockito` and `bloc_test`. Unit tests live in `test/`.
- When adding mocked classes, run `build_runner` to regenerate.

Conventions & patterns to follow
- Use the feature `data/domain/presentation` split for new features.
- Register new dependencies in `lib/injection_container.dart` and prefer lazy singletons for services.
- When wiring a BLoC into the app, use `sl<YourBloc>()` in `MultiBlocProvider` (see `lib/main.dart`).
- Routes are managed with GetX: see `lib/core/routes/getx_route_module.dart` and `lib/core/routes/routes.dart`.

External integrations
- Firebase (core, auth) — configs under `android/app` and `ios/Runner` and `firebase_options.dart`.
- Key third-party libs: `get_it`, `get`, `flutter_bloc`, `bloc`, `equatable`, `http`, `shared_preferences`, `flutter_secure_storage`, `internet_connection_checker` (see `pubspec.yaml`).

When changing state persistence or lifecycle behavior
- Consult `lib/core/bloc_manager/README.md` for configuration flags (`BlocManagerConfig.*`) and examples for enabling persistence and cross-BLoC comms.

Examples to cite in PRs or fixes
- Bootstrapping DI: `lib/injection_container.dart` — new registrations must run in `init()` before app widgets rely on them.
- App bootstrap: `lib/main.dart` — shows `AppConfig.init()` and `MultiBlocProvider` usage.

Fail-fast checks for suggested edits
- Don't break DI order: ensure `sl` registrations that are required by others are registered first (or use lazy singletons when appropriate).
- If touching Firebase, ensure `firebase_options.dart` or platform configs are preserved.

If unsure, read these files next
- `lib/injection_container.dart` (DI wiring)
- `lib/main.dart` (app bootstrap)
- `lib/core/bloc_manager/README.md` and `lib/core/bloc/README.md` (state & lifecycle patterns)
- `pubspec.yaml` (dependencies and dev-dependencies)

If anything is unclear or you need more examples (e.g., typical BLoC shape, serialization helpers, or how to run specific platform builds), tell me which area to expand and I will iterate.

Expanded examples (practical snippets)

1) Quick DI example — add a new UseCase + Repo + Bloc
- Add usecase registration in `lib/injection_container.dart`:
  - `sl.registerLazySingleton(() => LoginUseCase(sl()));`
- Register repository implementation that depends on datasources and network info:
  - `sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()));`
- Register BLoC (factory - created per widget):
  - `sl.registerFactory(() => AuthBloc(loginUseCase: sl(), ...));`

2) Feature end-to-end wiring (example path)
- Feature layout: `lib/features/travellink/` contains `data/`, `domain/`, `presentation/`.
- Typical flow when adding `Foo` feature:
  - Add `FooRepository` interface under `domain/repositories` and `FooUseCase` under `domain/usecases`.
  - Implement `FooRepositoryImpl` in `data/repositories` using `data/datasources`.
  - Create `FooBloc` in `presentation/bloc` and use the usecase.
  - Wire everything in `lib/injection_container.dart`: datasources → repositories → usecases → blocs.
  - Wire BLoC into the app via `MultiBlocProvider` or `BlocManager` (see `lib/main.dart`).

3) BlocManager usage & state persistence
- This project uses a custom BlocManager to enable lifecycle, persistence and cross-BLoC events. Read `lib/core/bloc_manager/README.md` for full details.
- Quick pattern to enable persistence for `AuthBloc`:
  - Wrap your widget with `BlocManager<AuthBloc, AuthState>(
      config: BlocManagerConfig.production(getIt: GetIt.instance, enableStatePersistence: true, enableCrossBlocCommunication: true),
      create: (_) => sl<AuthBloc>()..add(AuthStarted()),
      child: AuthScreen(),
    );`
- Use the provided mixins (see `lib/core/bloc/mixins`) to implement `stateToJson` / `stateFromJson` for persistence.

4) CI / tests — quick notes
- Run unit/widget tests locally: `flutter test`.
- Regenerate mocks/build files: `flutter pub run build_runner build --delete-conflicting-outputs`.
- Tests rely on `mockito` + `bloc_test`. Place unit tests under `test/` and match existing naming patterns (look at `test/core/...`).

Try it (short checklist)
- `flutter pub get`
- `flutter pub run build_runner build --delete-conflicting-outputs` (after adding mocks)
- `flutter test`

When to ask for help
- If DI order is uncertain, point me to `lib/injection_container.dart` and I will propose correct registration order.
- If you want a full end-to-end example added as new files (usecase, repo impl, bloc, widget), say "generate example Foo feature" and I will scaffold it.
