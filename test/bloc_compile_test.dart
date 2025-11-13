import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/escrow/escrow_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/parcel/parcel_bloc.dart';
import 'package:parcel_am/features/travellink/domain/usecases/escrow_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/parcel_usecase.dart';
import 'package:mockito/mockito.dart';

class MockEscrowUseCase extends Mock implements EscrowUseCase {}
class MockParcelUseCase extends Mock implements ParcelUseCase {}

void main() {
  group('BLoC Compilation Test', () {
    test('EscrowBloc should instantiate', () {
      final mockUseCase = MockEscrowUseCase();
      final bloc = EscrowBloc(escrowUseCase: mockUseCase);
      expect(bloc, isNotNull);
      bloc.close();
    });

    test('ParcelBloc should instantiate', () {
      final mockUseCase = MockParcelUseCase();
      final bloc = ParcelBloc(parcelUseCase: mockUseCase);
      expect(bloc, isNotNull);
      bloc.close();
    });
  });
}
