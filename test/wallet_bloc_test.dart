import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/wallet/wallet_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';

void main() {
  group('WalletBloc', () {
    late WalletBloc walletBloc;

    setUp(() {
      walletBloc = WalletBloc();
    });

    tearDown(() {
      walletBloc.close();
    });

    test('initial state is InitialState', () {
      expect(walletBloc.state, isA<InitialState<WalletData>>());
    });

    test('WalletLoadRequested emits LoadedState with initial balance', () async {
      walletBloc.add(const WalletLoadRequested());

      await expectLater(
        walletBloc.stream,
        emitsInOrder([
          isA<LoadingState<WalletData>>(),
          isA<LoadedState<WalletData>>(),
        ]),
      );
    });

    test('WalletEscrowHoldRequested moves balance from available to pending', () async {
      walletBloc.add(const WalletLoadRequested());
      await Future.delayed(const Duration(milliseconds: 600));

      walletBloc.add(const WalletEscrowHoldRequested(
        transactionId: 'TXN_001',
        amount: 3650.0,
        packageId: 'PKG_001',
      ));

      await Future.delayed(const Duration(seconds: 3));

      final state = walletBloc.state;
      expect(state, isA<LoadedState<WalletData>>());
      
      if (state is LoadedState<WalletData> && state.data != null) {
        expect(state.data!.availableBalance, 46350.0);
        expect(state.data!.pendingBalance, 3650.0);
        expect(state.data!.escrowTransactions.length, 1);
        expect(state.data!.escrowTransactions.first.status, EscrowStatus.held);
      }
    });
  });
}
