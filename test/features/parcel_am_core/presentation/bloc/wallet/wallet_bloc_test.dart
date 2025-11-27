import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/services/connectivity_service.dart';
import 'package:parcel_am/features/parcel_am_core/data/helpers/idempotency_helper.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/wallet_entity.dart';
import 'package:parcel_am/features/parcel_am_core/domain/usecases/wallet_usecase.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_data.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_event.dart';

class MockWalletUseCase extends Mock implements WalletUseCase {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockWalletUseCase mockWalletUseCase;
  late MockConnectivityService mockConnectivityService;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockWalletUseCase = MockWalletUseCase();
    mockConnectivityService = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();

    when(() => mockConnectivityService.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivityService.isConnected).thenReturn(true);
    when(() => mockConnectivityService.startMonitoring()).thenReturn(null);
    when(() => mockConnectivityService.dispose()).thenReturn(null);
  });

  tearDown(() {
    connectivityController.close();
  });

  group('WalletBloc - Connectivity Tests', () {
    test('should start with isOnline = true by default', () {
      final bloc = WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      );

      expect(bloc.isOnline, isTrue);

      bloc.close();
    });

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should update isOnline when connectivity changes to offline',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      act: (bloc) async {
        // Give bloc time to set up
        await Future.delayed(const Duration(milliseconds: 100));
        connectivityController.add(false);
        await Future.delayed(const Duration(milliseconds: 100));
      },
      verify: (bloc) {
        expect(bloc.isOnline, isFalse);
      },
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should update isOnline when connectivity changes to online',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      act: (bloc) async {
        // Give bloc time to set up
        await Future.delayed(const Duration(milliseconds: 100));
        // First go offline
        connectivityController.add(false);
        await Future.delayed(const Duration(milliseconds: 100));
        // Then go back online
        connectivityController.add(true);
        await Future.delayed(const Duration(milliseconds: 100));
      },
      verify: (bloc) {
        expect(bloc.isOnline, isTrue);
      },
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should emit error when hold operation attempted while offline',
      build: () {
        final bloc = WalletBloc(
          walletUseCase: mockWalletUseCase,
          connectivityService: mockConnectivityService,
        );
        // Manually set offline state
        bloc.add(const WalletConnectivityChanged(isOnline: false));
        return bloc;
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 1000.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const WalletEscrowHoldRequested(
          transactionId: 'test-txn',
          amount: 100.0,
          packageId: 'pkg-123',
        ));
      },
      expect: () => [
        isA<LoadedState<WalletData>>(), // From connectivity change
        isA<AsyncErrorState<WalletData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          contains('No internet connection'),
        ),
      ],
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should emit error when release operation attempted while offline',
      build: () {
        final bloc = WalletBloc(
          walletUseCase: mockWalletUseCase,
          connectivityService: mockConnectivityService,
        );
        // Manually set offline state
        bloc.add(const WalletConnectivityChanged(isOnline: false));
        return bloc;
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 1000.0, pendingBalance: 500.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) async {
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const WalletEscrowReleaseRequested(
          transactionId: 'test-txn',
          amount: 100.0,
        ));
      },
      expect: () => [
        isA<LoadedState<WalletData>>(), // From connectivity change
        isA<AsyncErrorState<WalletData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          contains('No internet connection'),
        ),
      ],
    );
  });

  group('WalletBloc - Idempotency Tests', () {
    test('IdempotencyHelper generates valid transaction ID for hold operation',
        () {
      final transactionId = IdempotencyHelper.generateTransactionId('hold');

      expect(transactionId, startsWith('txn_hold_'));
      expect(IdempotencyHelper.isValidTransactionId(transactionId), isTrue);
    });

    test(
        'IdempotencyHelper generates valid transaction ID for release operation',
        () {
      final transactionId = IdempotencyHelper.generateTransactionId('release');

      expect(transactionId, startsWith('txn_release_'));
      expect(IdempotencyHelper.isValidTransactionId(transactionId), isTrue);
    });

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should call holdBalance with idempotency key when operation succeeds',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        final mockWallet = WalletEntity(
          id: 'wallet-1',
          userId: 'user-1',
          availableBalance: 900.0,
          heldBalance: 100.0,
          totalBalance: 1000.0,
          currency: 'NGN',
          lastUpdated: DateTime.now(),
        );
        when(() => mockWalletUseCase.holdBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Right(mockWallet));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 1000.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) async {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const WalletEscrowHoldRequested(
          transactionId: 'test-txn',
          amount: 100.0,
          packageId: 'pkg-123',
        ));
      },
      verify: (_) {
        // Verify that holdBalance was called with any idempotency key
        verify(() => mockWalletUseCase.holdBalance(
              any(),
              any(),
              any(),
              any(that: startsWith('txn_hold_')),
            )).called(1);
      },
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should call releaseBalance with idempotency key when operation succeeds',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        final mockWallet = WalletEntity(
          id: 'wallet-1',
          userId: 'user-1',
          availableBalance: 1100.0,
          heldBalance: 400.0,
          totalBalance: 1500.0,
          currency: 'NGN',
          lastUpdated: DateTime.now(),
        );
        when(() => mockWalletUseCase.releaseBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Right(mockWallet));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(
          availableBalance: 1000.0,
          pendingBalance: 500.0,
        ),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) async {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const WalletEscrowReleaseRequested(
          transactionId: 'test-txn',
          amount: 100.0,
        ));
      },
      verify: (_) {
        // Verify that releaseBalance was called with any idempotency key
        verify(() => mockWalletUseCase.releaseBalance(
              any(),
              any(),
              any(),
              any(that: startsWith('txn_release_')),
            )).called(1);
      },
    );
  });

  group('WalletBloc - Error Handling Tests', () {
    blocTest<WalletBloc, BaseState<WalletData>>(
      'should emit error with custom message for NoInternetFailure',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        when(() => mockWalletUseCase.holdBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => const Left(
              NoInternetFailure(failureMessage: 'No internet connection'),
            ));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 1000.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        bloc.add(const WalletEscrowHoldRequested(
          transactionId: 'test-txn',
          amount: 100.0,
          packageId: 'pkg-123',
        ));
      },
      expect: () => [
        isA<AsyncLoadingState<WalletData>>(),
        isA<AsyncErrorState<WalletData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          contains('No internet connection'),
        ),
      ],
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should emit error with balance details for insufficient balance',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 50.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        bloc.add(const WalletEscrowHoldRequested(
          transactionId: 'test-txn',
          amount: 100.0,
          packageId: 'pkg-123',
        ));
      },
      expect: () => [
        isA<AsyncErrorState<WalletData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          equals('Insufficient balance'),
        ),
      ],
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should emit error with held balance details for insufficient held balance',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        when(() => mockWalletUseCase.releaseBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => const Left(
              ValidationFailure(
                failureMessage: 'Insufficient held balance',
              ),
            ));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(
          availableBalance: 1000.0,
          pendingBalance: 50.0,
        ),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        bloc.add(const WalletEscrowReleaseRequested(
          transactionId: 'test-txn',
          amount: 100.0,
        ));
      },
      expect: () => [
        isA<AsyncLoadingState<WalletData>>(),
        isA<AsyncErrorState<WalletData>>().having(
          (state) => state.errorMessage,
          'errorMessage',
          contains('Insufficient held balance'),
        ),
      ],
    );
  });

  group('WalletBloc - Loading State Tests', () {
    blocTest<WalletBloc, BaseState<WalletData>>(
      'should show AsyncLoadingState during hold operation',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        final mockWallet = WalletEntity(
          id: 'wallet-1',
          userId: 'user-1',
          availableBalance: 900.0,
          heldBalance: 100.0,
          totalBalance: 1000.0,
          currency: 'NGN',
          lastUpdated: DateTime.now(),
        );
        when(() => mockWalletUseCase.holdBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Right(mockWallet));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(availableBalance: 1000.0),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        bloc.add(const WalletEscrowHoldRequested(
          transactionId: 'test-txn',
          amount: 100.0,
          packageId: 'pkg-123',
        ));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<AsyncLoadingState<WalletData>>(),
        isA<LoadedState<WalletData>>(),
      ],
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'should show AsyncLoadingState during release operation',
      build: () => WalletBloc(
        walletUseCase: mockWalletUseCase,
        connectivityService: mockConnectivityService,
      ),
      setUp: () {
        final mockWallet = WalletEntity(
          id: 'wallet-1',
          userId: 'user-1',
          availableBalance: 1100.0,
          heldBalance: 400.0,
          totalBalance: 1500.0,
          currency: 'NGN',
          lastUpdated: DateTime.now(),
        );
        when(() => mockWalletUseCase.releaseBalance(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Right(mockWallet));
      },
      seed: () => LoadedState<WalletData>(
        data: const WalletData(
          availableBalance: 1000.0,
          pendingBalance: 500.0,
        ),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        // Set wallet ID before operation
        bloc.currentWalletId = 'wallet-1';
        bloc.add(const WalletEscrowReleaseRequested(
          transactionId: 'test-txn',
          amount: 100.0,
        ));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<AsyncLoadingState<WalletData>>(),
        isA<LoadedState<WalletData>>(),
      ],
    );
  });
}
