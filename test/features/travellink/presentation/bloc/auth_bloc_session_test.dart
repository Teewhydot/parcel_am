import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/travellink/domain/usecases/auth_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/kyc_usecase.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';

@GenerateMocks([
  AuthUseCase,
  KycUseCase,
])
import 'auth_bloc_session_test.mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockAuthUseCase mockAuthUseCase;
  late MockKycUseCase mockKycUseCase;

  final tUser = UserEntity(
    uid: 'user123',
    displayName: 'John Doe',
    email: 'john@example.com',
    isVerified: true,
    verificationStatus: 'verified',
    createdAt: DateTime.now(),
    additionalData: {},
    kycStatus: KycStatus.notStarted,
  );

  setUp(() {
    mockAuthUseCase = MockAuthUseCase();
    mockKycUseCase = MockKycUseCase();

    bloc = AuthBloc(
     
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthStarted Session Restoration', () {
    test('emits LoadingState then InitialState when getCurrentUser returns null', () async {
      when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
    });

    test('emits LoadingState then InitialState when getCurrentUser fails', () async {
      when(mockAuthUseCase.getCurrentUser()).thenAnswer(
        (_) async => const Left(AuthFailure(failureMessage: 'Auth failed')),
      );

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
    });

    test('emits LoadedState when user exists', () async {
      when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => Right(tUser));
      when(mockKycUseCase.watchKycStatus(any)).thenAnswer((_) => Stream.value('notStarted'));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        bloc.state,
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user,
          'user',
          tUser,
        ),
      );
    });
  });

  group('AuthLoginRequested', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    test('emits LoadingState then SuccessState and LoadedState on successful login', () async {
      when(mockAuthUseCase.login(tEmail, tPassword)).thenAnswer((_) async => Right(tUser));
      when(mockKycUseCase.watchKycStatus(any)).thenAnswer((_) => Stream.value('notStarted'));

      bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<LoadedState<AuthData>>());
    });

    test('emits LoadingState then ErrorState on failed login', () async {
      when(mockAuthUseCase.login(tEmail, tPassword)).thenAnswer(
        (_) async => const Left(AuthFailure(failureMessage: 'Invalid credentials')),
      );

      bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        bloc.state,
        isA<ErrorState<AuthData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          'Invalid credentials',
        ),
      );
    });
  });

  group('AuthLogoutRequested', () {
    test('emits LoadingState then InitialState on successful logout', () async {
      when(mockAuthUseCase.logout()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
    });

    test('emits LoadingState then ErrorState on failed logout', () async {
      when(mockAuthUseCase.logout()).thenAnswer(
        (_) async => const Left(ServerFailure(failureMessage: 'Logout failed')),
      );

      bloc.add(const AuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        bloc.state,
        isA<ErrorState<AuthData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          'Logout failed',
        ),
      );
    });
  });
}
