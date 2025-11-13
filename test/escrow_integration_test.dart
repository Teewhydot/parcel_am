import 'package:flutter_test/flutter_test.dart';
import 'package:parcel/features/travellink/presentation/bloc/package/package_bloc.dart';
import 'package:parcel/features/travellink/presentation/bloc/package/package_event.dart';
import 'package:parcel/features/travellink/presentation/bloc/package/package_state.dart';
import 'package:parcel/features/travellink/data/datasources/package_remote_data_source.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([PackageRemoteDataSource])
import 'escrow_integration_test.mocks.dart';

void main() {
  group('Escrow Integration Tests', () {
    late PackageBloc bloc;
    late MockPackageRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockPackageRemoteDataSource();
      bloc = PackageBloc(dataSource: mockDataSource);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state should be correct', () {
      expect(bloc.state.isLoading, false);
      expect(bloc.state.package, null);
      expect(bloc.state.escrowReleaseStatus, null);
    });

    test('EscrowReleaseRequested should update status to processing', () async {
      when(mockDataSource.releaseEscrow(
        packageId: anyNamed('packageId'),
        transactionId: anyNamed('transactionId'),
      )).thenAnswer((_) async => Future.value());

      bloc.add(const EscrowReleaseRequested(
        packageId: 'test-id',
        transactionId: 'trans-id',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PackageState>(
            (state) => state.escrowReleaseStatus == EscrowReleaseStatus.processing,
          ),
          predicate<PackageState>(
            (state) => state.escrowReleaseStatus == EscrowReleaseStatus.released,
          ),
        ]),
      );
    });

    test('EscrowDisputeRequested should create dispute', () async {
      when(mockDataSource.createDispute(
        packageId: anyNamed('packageId'),
        transactionId: anyNamed('transactionId'),
        reason: anyNamed('reason'),
      )).thenAnswer((_) async => 'dispute-id-123');

      bloc.add(const EscrowDisputeRequested(
        packageId: 'test-id',
        transactionId: 'trans-id',
        reason: 'Test reason',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PackageState>(
            (state) => state.escrowReleaseStatus == EscrowReleaseStatus.processing,
          ),
          predicate<PackageState>(
            (state) =>
                state.escrowReleaseStatus == EscrowReleaseStatus.disputed &&
                state.disputeId == 'dispute-id-123',
          ),
        ]),
      );
    });
  });
}
