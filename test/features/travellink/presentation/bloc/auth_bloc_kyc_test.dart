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
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';

@GenerateMocks([
  LoginUseCase,
  RegisterUseCase,
  LogoutUseCase,
  GetCurrentUserUseCase,
  ResetPasswordUseCase,
  WatchKycStatusUseCase,
])
import 'auth_bloc_kyc_test.mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockWatchKycStatusUseCase mockWatchKycStatusUseCase;

  final tUser = UserEntity(
    uid: 'user123',
    displayName: 'John Doe',
    email: 'john@example.com',
    isVerified: true,
    verificationStatus: 'verified',
    createdAt: DateTime.now(),
    additionalData: {},
    kycStatus: 'not_submitted',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockWatchKycStatusUseCase = MockWatchKycStatusUseCase();

    bloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
      watchKycStatusUseCase: mockWatchKycStatusUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is InitialState', () {
    expect(bloc.state, equals(const InitialState<AuthData>()));
  });

  group('AuthKycStatusUpdated', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates user kycStatus when AuthKycStatusUpdated is added',
      build: () {
        when(mockGetCurrentUserUseCase()).thenAnswer((_) async => Right(tUser));
        when(mockWatchKycStatusUseCase(any)).thenAnswer((_) => Stream.value('approved'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const AuthKycStatusUpdated('approved'));
      },
      skip: 2,
      expect: () => [
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.kycStatus,
          'kycStatus',
          'approved',
        ),
      ],
    );
  });

  group('KYC Status Stream Integration', () {
    test('subscribes to KYC status stream after login', () async {
      final kycStatusController = StreamController<String>();
      
      when(mockLoginUseCase(any)).thenAnswer((_) async => Right(tUser));
      when(mockWatchKycStatusUseCase(any)).thenAnswer((_) => kycStatusController.stream);

      bloc.add(const AuthLoginRequested(
        email: 'john@example.com',
        password: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      kycStatusController.add('pending');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        bloc.state,
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.kycStatus,
          'kycStatus',
          'pending',
        ),
      );

      kycStatusController.close();
    });

    test('unsubscribes from KYC status stream on logout', () async {
      final kycStatusController = StreamController<String>();
      
      when(mockLoginUseCase(any)).thenAnswer((_) async => Right(tUser));
      when(mockWatchKycStatusUseCase(any)).thenAnswer((_) => kycStatusController.stream);
      when(mockLogoutUseCase()).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthLoginRequested(
        email: 'john@example.com',
        password: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const AuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));

      kycStatusController.close();
    });
  });
}
