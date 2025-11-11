import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/travellink/domain/usecases/login_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/register_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/logout_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/get_current_user_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/watch_kyc_status_usecase.dart';
import 'package:parcel_am/features/travellink/domain/repositories/auth_repository.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/domain/entities/auth_token_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';

@GenerateMocks([
  LoginUseCase,
  RegisterUseCase,
  LogoutUseCase,
  GetCurrentUserUseCase,
  ResetPasswordUseCase,
  WatchKycStatusUseCase,
  AuthRepository,
])
import 'auth_bloc_session_test.mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockWatchKycStatusUseCase mockWatchKycStatusUseCase;
  late MockAuthRepository mockAuthRepository;

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
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockWatchKycStatusUseCase = MockWatchKycStatusUseCase();
    mockAuthRepository = MockAuthRepository();

    bloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
      watchKycStatusUseCase: mockWatchKycStatusUseCase,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthStarted Session Restoration', () {
    test('emits InitialState when no token is stored', () async {
      when(mockAuthRepository.getStoredToken()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
      verifyNever(mockAuthRepository.clearStoredData());
    });

    test('emits InitialState and clears data when token is expired', () async {
      final expiredToken = AuthTokenEntity(
        accessToken: 'expired_token',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      when(mockAuthRepository.getStoredToken()).thenAnswer((_) async => Right(expiredToken));
      when(mockAuthRepository.clearStoredData()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockAuthRepository.clearStoredData()).called(1);
      expect(bloc.state, equals(const InitialState<AuthData>()));
    });

    test('emits LoadedState when token is valid and user exists', () async {
      final validToken = AuthTokenEntity(
        accessToken: 'valid_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(mockAuthRepository.getStoredToken()).thenAnswer((_) async => Right(validToken));
      when(mockGetCurrentUserUseCase()).thenAnswer((_) async => Right(tUser));
      when(mockWatchKycStatusUseCase(any)).thenAnswer((_) => Stream.value('notStarted'));

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
      verifyNever(mockAuthRepository.clearStoredData());
    });

    test('emits InitialState and clears data when user fetch fails', () async {
      final validToken = AuthTokenEntity(
        accessToken: 'valid_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(mockAuthRepository.getStoredToken()).thenAnswer((_) async => Right(validToken));
      when(mockGetCurrentUserUseCase()).thenAnswer((_) async => const Left(AuthFailure(failureMessage: 'Auth failed')));
      when(mockAuthRepository.clearStoredData()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockAuthRepository.clearStoredData()).called(1);
      expect(bloc.state, equals(const InitialState<AuthData>()));
    });

    test('emits InitialState when token fetch fails', () async {
      when(mockAuthRepository.getStoredToken()).thenAnswer((_) async => const Left(CacheFailure(failureMessage: 'Cache error')));

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
      verifyNever(mockAuthRepository.clearStoredData());
    });
  });
}
