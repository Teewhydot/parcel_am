import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';

void main() {
  late WalletBloc walletBloc;

  setUp(() {
    walletBloc = WalletBloc();
  });

  tearDown(() {
    walletBloc.close();
  });

  group('WalletBloc', () {
    test('initial state is InitialState', () {
      expect(walletBloc.state, isA<InitialState<WalletData>>());
    });

    blocTest<WalletBloc, BaseState<WalletData>>(
      'emits [LoadingState, LoadedState] when WalletStarted is added',
      build: () => walletBloc,
      act: (bloc) => bloc.add(const WalletStarted('user123')),
      expect: () => [
        isA<LoadingState<WalletData>>(),
        isA<LoadedState<WalletData>>()
            .having((state) => state.data?.availableBalance, 'availableBalance', 50000.0)
            .having((state) => state.data?.pendingBalance, 'pendingBalance', 0.0),
      ],
    );

    blocTest<WalletBloc, BaseState<WalletData>>(
      'emits [LoadedState] when WalletBalanceUpdated is added',
      build: () => walletBloc,
      act: (bloc) => bloc.add(const WalletBalanceUpdated(
        availableBalance: 50000.0,
        pendingBalance: 15000.0,
      )),
      expect: () => [
        isA<LoadedState<WalletData>>()
            .having((state) => state.data?.availableBalance, 'availableBalance', 50000.0)
            .having((state) => state.data?.pendingBalance, 'pendingBalance', 15000.0)
            .having((state) => state.data?.balance, 'balance', 65000.0),
      ],
    );

    test('balance calculation is correct', () {
      const walletData = WalletData(
        availableBalance: 10000.0,
        pendingBalance: 5000.0,
      );
      expect(walletData.balance, 15000.0);
    });

    test('escrowBalance returns pendingBalance', () {
      const walletData = WalletData(
        availableBalance: 10000.0,
        pendingBalance: 5000.0,
      );
      expect(walletData.escrowBalance, 5000.0);
    });
  });
}
