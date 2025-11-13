import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/escrow/escrow_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/escrow/escrow_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/escrow/escrow_state.dart';

void main() {
  late EscrowBloc escrowBloc;

  setUp(() {
    escrowBloc = EscrowBloc();
  });

  tearDown(() {
    escrowBloc.close();
  });

  group('EscrowBloc', () {
    test('initial state has idle status', () {
      expect(escrowBloc.state.status, EscrowStatus.idle);
    });

    blocTest<EscrowBloc, EscrowState>(
      'emits [holding, held] when EscrowHoldRequested is added',
      build: () => escrowBloc,
      act: (bloc) => bloc.add(const EscrowHoldRequested(
        transactionId: 'TXN_123',
        amount: 1000.0,
        packageId: 'PKG_123',
      )),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.holding)
            .having((s) => s.transactionId, 'transactionId', 'TXN_123')
            .having((s) => s.amount, 'amount', 1000.0),
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.held),
      ],
    );

    blocTest<EscrowBloc, EscrowState>(
      'emits [releasing, released] when EscrowReleaseRequested is added',
      build: () => escrowBloc,
      seed: () => const EscrowState(
        status: EscrowStatus.held,
        transactionId: 'TXN_123',
        amount: 1000.0,
      ),
      act: (bloc) => bloc.add(const EscrowReleaseRequested('TXN_123')),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.releasing),
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.released),
      ],
    );

    blocTest<EscrowBloc, EscrowState>(
      'emits [cancelling, cancelled] when EscrowCancelRequested is added',
      build: () => escrowBloc,
      seed: () => const EscrowState(
        status: EscrowStatus.held,
        transactionId: 'TXN_123',
        amount: 1000.0,
      ),
      act: (bloc) => bloc.add(const EscrowCancelRequested('TXN_123')),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.cancelling),
        isA<EscrowState>()
            .having((s) => s.status, 'status', EscrowStatus.cancelled),
      ],
    );

    test('statusStream emits status updates', () async {
      final statusUpdates = <EscrowStatus>[];
      final subscription = escrowBloc.statusStream.listen((state) {
        statusUpdates.add(state.status);
      });

      escrowBloc.add(const EscrowHoldRequested(
        transactionId: 'TXN_123',
        amount: 1000.0,
        packageId: 'PKG_123',
      ));

      await Future.delayed(const Duration(seconds: 2));

      expect(statusUpdates, contains(EscrowStatus.holding));
      expect(statusUpdates, contains(EscrowStatus.held));

      await subscription.cancel();
    });
  });
}
