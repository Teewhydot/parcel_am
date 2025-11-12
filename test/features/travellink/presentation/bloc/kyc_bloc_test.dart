import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:parcel_am/features/travellink/domain/usecases/kyc_usecase.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_state.dart';
import 'package:parcel_am/core/errors/failures.dart';

@GenerateMocks([KycUseCase])
import 'kyc_bloc_test.mocks.dart';

void main() {
  late KycBloc bloc;
  late MockKycUseCase mockKycUseCase;

  setUp(() {
    mockKycUseCase = MockKycUseCase();

    bloc = KycBloc(
      kycUseCase: mockKycUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is KycInitial', () {
    expect(bloc.state, equals(const KycInitial()));
  });

  group('KycSubmitRequested', () {
    const tUserId = 'user123';
    const tFullName = 'John Doe';
    const tDateOfBirth = '1990-01-01';
    const tAddress = '123 Main St';
    const tIdType = 'passport';
    const tIdNumber = 'ABC123';
    const tFrontImagePath = '/path/front.jpg';
    const tBackImagePath = '/path/back.jpg';
    const tSelfieImagePath = '/path/selfie.jpg';

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycSubmitted] when submission is successful',
      build: () {
        when(mockKycUseCase.submitKyc(
          userId: anyNamed('userId'),
          fullName: anyNamed('fullName'),
          dateOfBirth: anyNamed('dateOfBirth'),
          address: anyNamed('address'),
          idType: anyNamed('idType'),
          idNumber: anyNamed('idNumber'),
          frontImagePath: anyNamed('frontImagePath'),
          backImagePath: anyNamed('backImagePath'),
          selfieImagePath: anyNamed('selfieImagePath'),
        )).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const KycSubmitRequested(
        fullName: tFullName,
        dateOfBirth: tDateOfBirth,
        address: tAddress,
        idType: tIdType,
        idNumber: tIdNumber,
        frontImagePath: tFrontImagePath,
        backImagePath: tBackImagePath,
        selfieImagePath: tSelfieImagePath,
      )),
      expect: () => [
        const KycLoading(message: 'Submitting KYC documents...'),
        isA<KycSubmitted>(),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycError] when submission fails',
      build: () {
        when(mockKycUseCase.submitKyc(
          userId: anyNamed('userId'),
          fullName: anyNamed('fullName'),
          dateOfBirth: anyNamed('dateOfBirth'),
          address: anyNamed('address'),
          idType: anyNamed('idType'),
          idNumber: anyNamed('idNumber'),
          frontImagePath: anyNamed('frontImagePath'),
          backImagePath: anyNamed('backImagePath'),
          selfieImagePath: anyNamed('selfieImagePath'),
        )).thenAnswer(
          (_) async => const Left(ServerFailure(failureMessage: 'Submission failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const KycSubmitRequested(
        fullName: tFullName,
        dateOfBirth: tDateOfBirth,
        address: tAddress,
        idType: tIdType,
        idNumber: tIdNumber,
        frontImagePath: tFrontImagePath,
        backImagePath: tBackImagePath,
        selfieImagePath: tSelfieImagePath,
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
        when(mockKycUseCase.getKycStatus(any)).thenAnswer((_) async => const Right('approved'));
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
        when(mockKycUseCase.getKycStatus(any)).thenAnswer((_) async => const Right('rejected'));
        return bloc;
      },
      act: (bloc) => bloc.add(const KycStatusRequested()),
      expect: () => [
        const KycLoading(message: 'Checking KYC status...'),
        isA<KycRejected>(),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycSubmitted] when status is pending',
      build: () {
        when(mockKycUseCase.getKycStatus(any)).thenAnswer((_) async => const Right('pending'));
        return bloc;
      },
      act: (bloc) => bloc.add(const KycStatusRequested()),
      expect: () => [
        const KycLoading(message: 'Checking KYC status...'),
        isA<KycSubmitted>(),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [KycLoading, KycError] when status check fails',
      build: () {
        when(mockKycUseCase.getKycStatus(any)).thenAnswer(
          (_) async => const Left(ServerFailure(failureMessage: 'Failed to fetch status')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const KycStatusRequested()),
      expect: () => [
        const KycLoading(message: 'Checking KYC status...'),
        const KycError(errorMessage: 'Failed to fetch status'),
      ],
    );
  });
}
