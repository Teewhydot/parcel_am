import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
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
import 'auth_bloc_kyc_test.mocks.dart';

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

    bloc = AuthBloc();
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is InitialState', () {
    expect(bloc.state, equals(const InitialState<AuthData>()));
  });

  group('AuthStarted Session Restoration', () {
    test('emits InitialState when getCurrentUser returns null', () async {
      when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => const Right(null));

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

    test('emits InitialState when user fetch fails', () async {
      when(mockAuthUseCase.getCurrentUser()).thenAnswer(
        (_) async => const Left(AuthFailure(failureMessage: 'Auth failed')),
      );

      bloc.add(const AuthStarted());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, equals(const InitialState<AuthData>()));
    });
  });

  group('AuthKycStatusUpdated', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates user kycStatus when AuthKycStatusUpdated is added',
      build: () {
        when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => Right(tUser));
        when(mockKycUseCase.watchKycStatus(any)).thenAnswer((_) => Stream.value('approved'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const AuthKycStatusUpdated('approved'));
      },
      skip: 3, // Skip LoadingState, LoadedState from AuthStarted, and LoadedState from stream
      expect: () => [
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.kycStatus,
          'kycStatus',
          KycStatus.approved,
        ),
      ],
    );
  });

  group('KYC Status Stream Integration', () {
    test('subscribes to KYC status stream after login', () async {
      final kycStatusController = StreamController<String>();

      when(mockAuthUseCase.login(any, any)).thenAnswer((_) async => Right(tUser));
      when(mockKycUseCase.watchKycStatus(any)).thenAnswer((_) => kycStatusController.stream);

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
          KycStatus.pending,
        ),
      );

      kycStatusController.close();
    });

    test('unsubscribes from KYC status stream on logout', () async {
      final kycStatusController = StreamController<String>();

      when(mockAuthUseCase.login(any, any)).thenAnswer((_) async => Right(tUser));
      when(mockKycUseCase.watchKycStatus(any)).thenAnswer((_) => kycStatusController.stream);
      when(mockAuthUseCase.logout()).thenAnswer((_) async => const Right(null));

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
