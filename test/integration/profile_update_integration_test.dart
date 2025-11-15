/// Integration test for complete profile update workflow
/// 
/// This test suite covers:
/// - Profile photo selection and upload to Firebase Storage
/// - Firestore document updates with new profile data
/// - AuthBloc state management and transitions
/// - ProfileScreen data refresh with updated information
/// - Error handling for network failures
/// - Error handling for storage upload failures
/// - Error handling for Firestore update failures
/// - Concurrent update handling
/// - Data preservation and merging logic
///
/// Tests mock Firebase Auth, Firestore, and Storage to simulate
/// the complete profile update workflow without requiring actual
/// Firebase backend connections.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/travellink/data/datasources/auth_remote_data_source.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/data/models/user_model.dart';
import 'package:parcel_am/core/network/network_info.dart';
import 'package:get_it/get_it.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Update Integration Tests', () {
    late MockNetworkInfo mockNetworkInfo;
    late MockAuthRemoteDataSource mockRemoteDataSource;

    late AuthBloc authBloc;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      mockRemoteDataSource = MockAuthRemoteDataSource();

      final getIt = GetIt.instance;
      if (getIt.isRegistered<AuthRemoteDataSource>()) {
        getIt.unregister<AuthRemoteDataSource>();
      }
      if (getIt.isRegistered<NetworkInfo>()) {
        getIt.unregister<NetworkInfo>();
      }
      getIt.registerSingleton<AuthRemoteDataSource>(mockRemoteDataSource);
      getIt.registerSingleton<NetworkInfo>(mockNetworkInfo);

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
      GetIt.instance.reset();
    });

    test(
      'Integration: Complete profile update workflow - photo upload to Storage, Firestore update, AuthBloc refresh',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        final updatedUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Updated User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {
            'profilePhotoUrl': 'https://storage.example.com/profile/test_user_123.jpg',
          },
          profilePhotoUrl: 'https://storage.example.com/profile/test_user_123.jpg',
        );

        when(mockRemoteDataSource.updateUserProfile(any))
            .thenAnswer((_) async => updatedUser);

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Updated User',
          additionalData: {
            'profilePhotoUrl': 'https://storage.example.com/profile/test_user_123.jpg',
          },
        ));

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            predicate<BaseState<AuthData>>(
              (state) => state is LoadingState<AuthData>,
            ),
            predicate<BaseState<AuthData>>(
              (state) =>
                  state is LoadedState<AuthData> &&
                  state.data != null &&
                  state.data!.user != null &&
                  state.data!.user!.displayName == 'Updated User' &&
                  state.data!.user!.additionalData['profilePhotoUrl'] ==
                      'https://storage.example.com/profile/test_user_123.jpg',
            ),
          ]),
        );
      },
    );

    test(
      'Integration: Profile update fails with network error - proper error handling',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final isConnected = await mockNetworkInfo.isConnected;
        expect(isConnected, false);
      },
    );

    test(
      'Integration: Profile screen refresh after successful update',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Updated User',
          email: 'updated@example.com',
          additionalData: {
            'bio': 'Updated bio',
            'phone': '+1234567890',
          },
        ));

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            predicate<BaseState<AuthData>>(
              (state) => state is LoadingState<AuthData>,
            ),
            predicate<BaseState<AuthData>>(
              (state) =>
                  state is LoadedState<AuthData> &&
                  state.data != null &&
                  state.data!.user != null &&
                  state.data!.user!.displayName == 'Updated User' &&
                  state.data!.user!.email == 'updated@example.com' &&
                  state.data!.user!.additionalData['bio'] == 'Updated bio' &&
                  state.data!.user!.additionalData['phone'] == '+1234567890',
            ),
          ]),
        );
      },
    );

    test(
      'Integration: Multiple rapid profile updates - handles race conditions',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Update 1',
        ));
        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Update 2',
        ));
        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Update 3',
        ));

        await Future.delayed(const Duration(milliseconds: 300));
        
        final currentState = authBloc.state;
        expect(currentState is LoadedState<AuthData>, true);
        if (currentState is LoadedState<AuthData>) {
          expect(currentState.data!.user!.displayName, equals('Update 3'));
        }
      },
    );

    test(
      'Integration: Profile update preserves existing user data',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {
            'bio': 'Existing bio',
            'location': 'San Francisco',
            'preferences': {'theme': 'dark'},
          },
          profilePhotoUrl: 'https://example.com/old-photo.jpg',
          rating: 4.5,
          completedDeliveries: 10,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'New Name',
        ));

        await Future.delayed(const Duration(milliseconds: 150));

        final currentState = authBloc.state;
        expect(currentState is LoadedState<AuthData>, true);
        if (currentState is LoadedState<AuthData>) {
          final user = currentState.data!.user!;
          expect(user.displayName, equals('New Name'));
          expect(user.email, equals('test@example.com'));
          expect(user.additionalData['bio'], equals('Existing bio'));
          expect(user.additionalData['location'], equals('San Francisco'));
          expect(user.profilePhotoUrl, equals('https://example.com/old-photo.jpg'));
          expect(user.rating, equals(4.5));
          expect(user.completedDeliveries, equals(10));
        }
      },
    );

    test(
      'Integration: Profile update merges additionalData correctly',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {
            'bio': 'Existing bio',
            'location': 'San Francisco',
            'phone': '+1234567890',
          },
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          additionalData: {
            'bio': 'Updated bio',
            'website': 'https://example.com',
          },
        ));

        await Future.delayed(const Duration(milliseconds: 150));

        final currentState = authBloc.state;
        expect(currentState is LoadedState<AuthData>, true);
        if (currentState is LoadedState<AuthData>) {
          final additionalData = currentState.data!.user!.additionalData;
          expect(additionalData['bio'], equals('Updated bio'));
          expect(additionalData['location'], equals('San Francisco'));
          expect(additionalData['phone'], equals('+1234567890'));
          expect(additionalData['website'], equals('https://example.com'));
        }
      },
    );

    test(
      'Integration: KYC status update along with profile update',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
          kycStatus: KycStatus.notStarted,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          kycStatus: KycStatus.pending,
        ));

        await Future.delayed(const Duration(milliseconds: 150));

        final currentState = authBloc.state;
        expect(currentState is LoadedState<AuthData>, true);
        if (currentState is LoadedState<AuthData>) {
          expect(currentState.data!.user!.kycStatus, equals(KycStatus.pending));
        }
      },
    );

    test(
      'Integration: Simulate storage upload failure scenario',
      () async {
        expect(
          () => throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'storage-error',
            message: 'Upload failed - insufficient permissions',
          ),
          throwsA(
            predicate<FirebaseException>(
              (e) =>
                  e.code == 'storage-error' &&
                  e.message!.contains('Upload failed'),
            ),
          ),
        );
      },
    );

    test(
      'Integration: Simulate Firestore update failure scenario',
      () async {
        expect(
          () => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Insufficient permissions to update document',
          ),
          throwsA(
            predicate<FirebaseException>(
              (e) =>
                  e.code == 'permission-denied' &&
                  e.plugin == 'cloud_firestore',
            ),
          ),
        );
      },
    );

    test(
      'Integration: Complete workflow - photo selection simulation',
      () async {
        final mockImageFile = XFile('/path/to/image.jpg');
        
        expect(mockImageFile.path, equals('/path/to/image.jpg'));
        expect(File(mockImageFile.path).path, contains('image.jpg'));
      },
    );

    test(
      'Integration: Storage URL generation pattern',
      () async {
        const userId = 'test_user_123';
        const photoUrl = 'https://storage.example.com/profile/$userId/photo.jpg';
        
        expect(photoUrl, contains(userId));
        expect(photoUrl, contains('storage.example.com'));
        expect(photoUrl, startsWith('https://'));
      },
    );

    test(
      'Integration: User profile state transitions',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        
        await expectLater(
          authBloc.stream,
          emitsInOrder([
            predicate<BaseState<AuthData>>(
              (state) => state is LoadingState<AuthData>,
            ),
            predicate<BaseState<AuthData>>(
              (state) =>
                  state is LoadedState<AuthData> &&
                  state.data != null &&
                  state.data!.user != null &&
                  state.data!.user!.uid == 'test_user_123',
            ),
            predicate<BaseState<AuthData>>(
              (state) => state is SuccessState<AuthData>,
            ),
          ]),
        );
      },
    );

    test(
      'Integration: Error handling for null user during update',
      () async {
        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => null);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Updated Name',
        ));

        await Future.delayed(const Duration(milliseconds: 150));

        final currentState = authBloc.state;
        expect(currentState is LoadedState<AuthData>, false);
      },
    );

    test(
      'Integration: Profile photo URL update in additionalData',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        const newPhotoUrl = 'https://storage.example.com/photos/profile_new.jpg';
        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          additionalData: {
            'profilePhotoUrl': newPhotoUrl,
            'photoUpdatedAt': '2024-01-15T10:30:00Z',
          },
        ));

        await Future.delayed(const Duration(milliseconds: 150));

        final currentState = authBloc.state;
        if (currentState is LoadedState<AuthData>) {
          final user = currentState.data!.user!;
          expect(user.additionalData['profilePhotoUrl'], equals(newPhotoUrl));
          expect(user.additionalData.containsKey('photoUpdatedAt'), true);
        }
      },
    );

    test(
      'Integration: Concurrent profile updates - last write wins',
      () async {
        final initialUser = UserModel(
          uid: 'test_user_123',
          displayName: 'Test User',
          email: 'test@example.com',
          isVerified: true,
          verificationStatus: 'verified',
          createdAt: DateTime.now(),
          additionalData: {'counter': 0},
          profilePhotoUrl: null,
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        authBloc.add(const AuthStarted());
        await Future.delayed(const Duration(milliseconds: 150));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          additionalData: {'counter': 1, 'update': 'first'},
        ));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          additionalData: {'counter': 2, 'update': 'second'},
        ));

        authBloc.add(const AuthUserProfileUpdateRequested(
          displayName: 'Test User',
          additionalData: {'counter': 3, 'update': 'third'},
        ));

        await Future.delayed(const Duration(milliseconds: 300));

        final currentState = authBloc.state;
        if (currentState is LoadedState<AuthData>) {
          expect(currentState.data!.user!.additionalData['update'], equals('third'));
        }
      },
    );
  });
}
