import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_state.dart';

void main() {
  late WalletBloc walletBloc;

  setUp(() {
    walletBloc = WalletBloc();
  });

  tearDown(() {
    walletBloc.close();
  });

  group('WalletBloc', () {
    test('initial state is WalletInitial', () {
      expect(walletBloc.state, const WalletInitial());
    });

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletLoaded] when WalletLoadRequested is added',
      build: () => walletBloc,
      act: (bloc) => bloc.add(const WalletLoadRequested()),
      expect: () => [
        const WalletLoading(),
        isA<WalletLoaded>()
            .having((state) => state.availableBalance, 'availableBalance', 45600.00)
            .having((state) => state.pendingBalance, 'pendingBalance', 12400.00),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoaded] when WalletBalanceUpdated is added',
      build: () => walletBloc,
      act: (bloc) => bloc.add(const WalletBalanceUpdated(
        availableBalance: 50000.0,
        pendingBalance: 15000.0,
      )),
      expect: () => [
        isA<WalletLoaded>()
            .having((state) => state.availableBalance, 'availableBalance', 50000.0)
            .having((state) => state.pendingBalance, 'pendingBalance', 15000.0)
            .having((state) => state.totalBalance, 'totalBalance', 65000.0),
      ],
    );

    test('totalBalance calculation is correct', () {
      const state = WalletLoaded(
        availableBalance: 10000.0,
        pendingBalance: 5000.0,
        lastUpdated: null,
      );
      expect(state.totalBalance, 15000.0);
    });
  });
}
