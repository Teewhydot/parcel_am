import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/kyc_usecase.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final KycUseCase _kycUseCase;
  StreamSubscription<String>? _kycStatusSubscription;

  KycBloc({
    required KycUseCase kycUseCase,
  })  : _kycUseCase = kycUseCase,
        super(const KycInitial()) {
    on<KycSubmitRequested>(_onSubmitRequested);
    on<KycStatusUpdated>(_onStatusUpdated);
    on<KycResubmitRequested>(_onResubmitRequested);
  }

  Future<void> _onSubmitRequested(
    KycSubmitRequested event,
    Emitter<KycState> emit,
  ) async {
    emit(const KycLoading(message: 'Submitting KYC documents...'));

    final result = await _kycUseCase.submitKyc(
      userId: '',
      fullName: event.fullName,
      dateOfBirth: event.dateOfBirth,
      address: event.address,
      idType: event.idType,
      idNumber: event.idNumber,
      frontImagePath: event.frontImagePath,
      backImagePath: event.backImagePath,
      selfieImagePath: event.selfieImagePath,
    );

    result.fold(
      (failure) {
        emit(KycError(errorMessage: failure.failureMessage));
      },
      (_) {
        emit(KycSubmitted(
          status: 'pending',
          submittedAt: DateTime.now(),
        ));
      },
    );
  }

  void _onStatusUpdated(
    KycStatusUpdated event,
    Emitter<KycState> emit,
  ) {
    _emitStatusState(event.status, emit);
  }

  Future<void> _onResubmitRequested(
    KycResubmitRequested event,
    Emitter<KycState> emit,
  ) async {
    emit(const KycLoading(message: 'Resubmitting KYC documents...'));

    final result = await _kycUseCase.submitKyc(
      userId: '',
      fullName: event.fullName,
      dateOfBirth: event.dateOfBirth,
      address: event.address,
      idType: event.idType,
      idNumber: event.idNumber,
      frontImagePath: event.frontImagePath,
      backImagePath: event.backImagePath,
      selfieImagePath: event.selfieImagePath,
    );

    result.fold(
      (failure) {
        emit(KycError(errorMessage: failure.failureMessage));
      },
      (_) {
        emit(KycSubmitted(
          status: 'pending',
          submittedAt: DateTime.now(),
        ));
      },
    );
  }

  void subscribeToKycStatus(String userId) {
    _kycStatusSubscription?.cancel();
    _kycStatusSubscription = _kycUseCase.watchKycStatus(userId).listen(
      (status) {
        add(KycStatusUpdated(status));
      },
    );
  }

  void _emitStatusState(String status, Emitter<KycState> emit) {
    switch (status) {
      case 'not_submitted':
        emit(const KycInitial());
        break;
      case 'pending':
        emit(KycSubmitted(
          status: status,
          submittedAt: DateTime.now(),
        ));
        break;
      case 'approved':
        emit(KycApproved(approvedAt: DateTime.now()));
        break;
      case 'rejected':
        emit(KycRejected(
          reason: 'Your KYC submission was rejected. Please resubmit with correct documents.',
          rejectedAt: DateTime.now(),
        ));
        break;
      default:
        emit(const KycInitial());
    }
  }

  @override
  Future<void> close() {
    _kycStatusSubscription?.cancel();
    return super.close();
  }
}
