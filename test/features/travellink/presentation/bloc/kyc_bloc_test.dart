import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/travellink/domain/usecases/submit_kyc_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/get_kyc_status_usecase.dart';
import 'package:parcel_am/features/travellink/domain/usecases/watch_kyc_status_usecase.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_state.dart';
import 'package:parcel_am/core/errors/failures.dart';

@GenerateMocks([SubmitKycUseCase, GetKycStatusUseCase, WatchKycStatusUseCase])
import 'kyc_bloc_test.mocks.dart';

void main() {
  late KycBloc bloc;
  late MockSubmitKycUseCase mockSubmitKycUseCase;
  late MockGetKycStatusUseCase mockGetKycStatusUseCase;
  late MockWatchKycStatusUseCase mockWatchKycStatusUseCase;

  setUp(() {
    mockSubmitKycUseCase = MockSubmitKycUseCase();
    mockGetKycStatusUseCase = MockGetKycStatusUseCase();
    mockWatchKycStatusUseCase = MockWatchKycStatusUseCase();

    bloc = KycBloc(
      submitKycUseCase: mockSubmitKycUseCase,
      getKycStatusUseCase: mockGetKycStatusUseCase,
      watchKycStatusUseCase: mockWatchKycStatusUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is KycInitial', () {
    expect(bloc.state, equals(const KycInitial()));
  });

  group('KycSubmitRequested', () {
    final tParams = SubmitKycParams(
      userId: 'user123',
      fullName: 'John Doe',
      dateOfBirth: '1990-01-01',
      address: '123 Main St',
      idType: 'passport',
      idNumber: 'ABC123',
      frontImagePath: '/path/front.jpg',
      backImagePath: '/path/back.jpg',
      selfieImagePath: '/path/selfie.jpg',
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycSubmitted] when submission is successful',
      build: () {
        when(mockSubmitKycUseCase(any)).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(KycSubmitRequested(
        fullName: tParams.fullName,
        dateOfBirth: tParams.dateOfBirth,
        address: tParams.address,
        idType: tParams.idType,
        idNumber: tParams.idNumber,
        frontImagePath: tParams.frontImagePath,
        backImagePath: tParams.backImagePath,
        selfieImagePath: tParams.selfieImagePath,
      )),
      expect: () => [
        const KycLoading(message: 'Submitting KYC documents...'),
        isA<KycSubmitted>(),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycError] when submission fails',
      build: () {
        when(mockSubmitKycUseCase(any)).thenAnswer(
          (_) async => Left(ServerFailure(failureMessage: 'Submission failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(KycSubmitRequested(
        fullName: tParams.fullName,
        dateOfBirth: tParams.dateOfBirth,
        address: tParams.address,
        idType: tParams.idType,
        idNumber: tParams.idNumber,
        frontImagePath: tParams.frontImagePath,
        backImagePath: tParams.backImagePath,
        selfieImagePath: tParams.selfieImagePath,
      )),
      expect: () => [
        const KycLoading(message: 'Submitting KYC documents...'),
        const KycError(errorMessage: 'Submission failed'),
      ],
    );
  });

  group('KycStatusRequested', () {
    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycApproved] when status is approved',
      build: () {
        when(mockGetKycStatusUseCase(any)).thenAnswer((_) async => const Right('approved'));
        return bloc;
      },
      act: (bloc) => bloc.add(const KycStatusRequested()),
      expect: () => [
        const KycLoading(message: 'Checking KYC status...'),
        isA<KycApproved>(),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycRejected] when status is rejected',
      build: () {
        when(mockGetKycStatusUseCase(any)).thenAnswer((_) async => const Right('rejected'));
        return bloc;
      },
      act: (bloc) => bloc.add(const KycStatusRequested()),
      expect: () => [
        const KycLoading(message: 'Checking KYC status...'),
        isA<KycRejected>(),
      ],
    );
  });
}
