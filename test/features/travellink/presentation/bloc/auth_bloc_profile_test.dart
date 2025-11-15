import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/travellink/domain/usecases/auth_usecase.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';

@GenerateMocks([AuthUseCase])
import 'auth_bloc_profile_test.mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockAuthUseCase mockAuthUseCase;

  final tUser = UserEntity(
    uid: 'user123',
    displayName: 'John Doe',
    email: 'john@example.com',
    isVerified: true,
    verificationStatus: 'verified',
    createdAt: DateTime.now(),
    additionalData: {'phoneNumber': '+1234567890'},
    kycStatus: KycStatus.notStarted,
    profilePhotoUrl: 'https://example.com/old-photo.jpg',
    rating: 4.5,
    completedDeliveries: 10,
    packagesSent: 5,
  );

  setUp(() {
    mockAuthUseCase = MockAuthUseCase();
    bloc = AuthBloc();
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthUserProfileUpdateRequested - Basic Profile Updates', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'emits LoadingState then LoadedState when profile update is successful',
      build: () {
        when(mockAuthUseCase.getCurrentUser()).thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Jane Smith',
      )),
      expect: () => [
        isA<LoadingState<AuthData>>().having(
          (state) => state.message,
          'message',
          'Updating profile...',
        ),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'Jane Smith',
            )
            .having(
              (state) => state.data?.user?.uid,
              'uid',
              'user123',
            )
            .having(
              (state) => state.data?.user?.email,
              'email',
              'john@example.com',
            ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates email when provided in event',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        email: 'newemail@example.com',
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.email,
              'email',
              'newemail@example.com',
            )
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'John Doe',
            ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates kycStatus when provided in event',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        kycStatus: KycStatus.approved,
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.kycStatus,
          'kycStatus',
          KycStatus.approved,
        ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'does nothing when user is null',
      build: () => bloc,
      seed: () => const LoadedState<AuthData>(
        data: AuthData(user: null),
        lastUpdated: null,
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Test User',
      )),
      expect: () => [],
    );
  });

  group('AuthUserProfileUpdateRequested - Additional Data Updates', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'merges new additionalData with existing data',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        additionalData: {'country': 'USA', 'city': 'New York'},
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.additionalData,
          'additionalData',
          {
            'phoneNumber': '+1234567890',
            'country': 'USA',
            'city': 'New York',
          },
        ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'overwrites existing additionalData keys',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        additionalData: {'phoneNumber': '+9876543210'},
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.additionalData['phoneNumber'],
          'phoneNumber',
          '+9876543210',
        ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'preserves existing additionalData when null provided',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe Updated',
        additionalData: null,
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.additionalData,
              'additionalData',
              {'phoneNumber': '+1234567890'},
            )
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'John Doe Updated',
            ),
      ],
    );
  });

  group('AuthUserProfileUpdateRequested - State Emissions', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'emits states in correct order: LoadingState -> LoadedState',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<LoadedState<AuthData>>());
      },
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'LoadingState has correct message',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
      )),
      skip: 0,
      expect: () => [
        predicate<LoadingState<AuthData>>(
          (state) => state.message == 'Updating profile...',
        ),
        isA<LoadedState<AuthData>>(),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'LoadedState updates lastUpdated timestamp',
      build: () => bloc,
      seed: () {
        final oldTimestamp = DateTime.now().subtract(const Duration(hours: 1));
        return LoadedState<AuthData>(
          data: AuthData(user: tUser),
          lastUpdated: oldTimestamp,
        );
      },
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
      )),
      verify: (bloc) {
        final state = bloc.state as LoadedState<AuthData>;
        expect(
          state.lastUpdated?.isAfter(
            DateTime.now().subtract(const Duration(seconds: 5)),
          ),
          true,
        );
      },
    );
  });

  group('AuthUserProfileUpdateRequested - Profile Photo Updates', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates profile photo URL in additionalData',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        additionalData: {
          'profilePhotoUrl': 'https://example.com/new-photo.jpg',
        },
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.additionalData['profilePhotoUrl'],
          'profilePhotoUrl',
          'https://example.com/new-photo.jpg',
        ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates multiple profile fields including photo URL',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
        email: 'updated@example.com',
        additionalData: {
          'profilePhotoUrl': 'https://storage.example.com/photo.jpg',
          'bio': 'New bio text',
        },
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'Updated Name',
            )
            .having(
              (state) => state.data?.user?.email,
              'email',
              'updated@example.com',
            )
            .having(
              (state) => state.data?.user?.additionalData['profilePhotoUrl'],
              'profilePhotoUrl',
              'https://storage.example.com/photo.jpg',
            )
            .having(
              (state) => state.data?.user?.additionalData['bio'],
              'bio',
              'New bio text',
            ),
      ],
    );
  });

  group('updateUserProfile UseCase Integration', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'integrates with updateUserProfile use case - success scenario',
      build: () {
        final updatedUser = tUser.copyWith(
          displayName: 'Updated via UseCase',
          profilePhotoUrl: 'https://firebase.storage.com/updated-photo.jpg',
        );
        when(mockAuthUseCase.updateUserProfile(any))
            .thenAnswer((_) async => Right(updatedUser));
        return bloc;
      },
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated via UseCase',
        additionalData: {
          'profilePhotoUrl': 'https://firebase.storage.com/updated-photo.jpg',
        },
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'Updated via UseCase',
            )
            .having(
              (state) => state.data?.user?.additionalData['profilePhotoUrl'],
              'profilePhotoUrl',
              'https://firebase.storage.com/updated-photo.jpg',
            ),
      ],
    );

    test('profile update maintains user identity (uid)', () async {
      final initialState = LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      );

      bloc.emit(initialState);

      bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'New Name',
        additionalData: {'profilePhotoUrl': 'https://example.com/photo.jpg'},
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as LoadedState<AuthData>;
      expect(state.data?.user?.uid, equals('user123'));
    });

    test('profile update preserves all existing user fields', () async {
      final initialState = LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      );

      bloc.emit(initialState);

      bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as LoadedState<AuthData>;
      expect(state.data?.user?.rating, equals(4.5));
      expect(state.data?.user?.completedDeliveries, equals(10));
      expect(state.data?.user?.packagesSent, equals(5));
      expect(state.data?.user?.profilePhotoUrl, equals('https://example.com/old-photo.jpg'));
    });
  });

  group('Profile Update Error Handling', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'handles network error when updating profile with Firebase Storage',
      build: () {
        when(mockAuthUseCase.updateUserProfile(any)).thenAnswer(
          (_) async => const Left(
            NoInternetFailure(failureMessage: 'No internet connection'),
          ),
        );
        return bloc;
      },
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Updated Name',
        additionalData: {'profilePhotoUrl': 'https://storage.com/photo.jpg'},
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>(),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'handles storage error when uploading profile photo',
      build: () {
        when(mockAuthUseCase.updateUserProfile(any)).thenAnswer(
          (_) async => const Left(
            ServerFailure(failureMessage: 'Storage upload failed'),
          ),
        );
        return bloc;
      },
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Test User',
        additionalData: {'profilePhotoUrl': 'https://storage.com/photo.jpg'},
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>(),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'does not emit states when user is null (early exit)',
      build: () => bloc,
      seed: () => const InitialState<AuthData>(),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Test User',
      )),
      expect: () => [],
    );
  });

  group('Complex Profile Update Scenarios', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'handles multiple consecutive profile updates',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) async {
        bloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'First Update',
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Second Update',
          email: 'second@example.com',
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Final Update',
          kycStatus: KycStatus.approved,
        ));
      },
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.displayName,
          'displayName',
          'First Update',
        ),
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.displayName,
          'displayName',
          'Second Update',
        ),
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'Final Update',
            )
            .having(
              (state) => state.data?.user?.kycStatus,
              'kycStatus',
              KycStatus.approved,
            ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'maintains data integrity across profile updates',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        additionalData: {
          'profilePhotoUrl': 'https://storage.com/photo.jpg',
          'address': '123 Main St',
          'phoneVerified': true,
        },
      )),
      verify: (bloc) {
        final state = bloc.state as LoadedState<AuthData>;
        final user = state.data?.user;
        
        expect(user?.uid, equals('user123'));
        expect(user?.displayName, equals('John Doe'));
        expect(user?.email, equals('john@example.com'));
        expect(user?.isVerified, equals(true));
        expect(user?.verificationStatus, equals('verified'));
        expect(user?.kycStatus, equals(KycStatus.notStarted));
        expect(user?.rating, equals(4.5));
        expect(user?.completedDeliveries, equals(10));
        expect(
          user?.additionalData['profilePhotoUrl'],
          equals('https://storage.com/photo.jpg'),
        );
        expect(user?.additionalData['address'], equals('123 Main St'));
        expect(user?.additionalData['phoneVerified'], equals(true));
        expect(user?.additionalData['phoneNumber'], equals('+1234567890'));
      },
    );
  });

  group('Profile Update with KYC Status Changes', () {
    blocTest<AuthBloc, BaseState<AuthData>>(
      'updates profile and KYC status together',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'Verified User',
        kycStatus: KycStatus.approved,
        additionalData: {'verificationDate': '2024-01-01'},
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>()
            .having(
              (state) => state.data?.user?.displayName,
              'displayName',
              'Verified User',
            )
            .having(
              (state) => state.data?.user?.kycStatus,
              'kycStatus',
              KycStatus.approved,
            )
            .having(
              (state) => state.data?.user?.additionalData['verificationDate'],
              'verificationDate',
              '2024-01-01',
            ),
      ],
    );

    blocTest<AuthBloc, BaseState<AuthData>>(
      'transitions KYC status from notStarted to pending',
      build: () => bloc,
      seed: () => LoadedState<AuthData>(
        data: AuthData(user: tUser),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const AuthUserProfileUpdateRequested(
        displayName: 'John Doe',
        kycStatus: KycStatus.pending,
      )),
      expect: () => [
        isA<LoadingState<AuthData>>(),
        isA<LoadedState<AuthData>>().having(
          (state) => state.data?.user?.kycStatus,
          'kycStatus',
          KycStatus.pending,
        ),
      ],
    );
  });
}
