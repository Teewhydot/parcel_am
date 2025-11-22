import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../file_upload/domain/use_cases/file_upload_usecase.dart';
import '../../domain/usecases/kyc_usecase.dart';
import 'kyc_event.dart';
import 'kyc_data.dart';

class KycBloc extends BaseBloC<KycEvent, BaseState<KycData>> {
  final _kycUseCase = KycUseCase();
  final _fileUploadUseCase = GetIt.instance<FileUploadUseCase>();

  KycBloc() : super(const InitialState<KycData>()) {
    on<KycDocumentUploadRequested>(_onDocumentUploadRequested);
    on<KycFinalSubmitRequested>(_onFinalSubmitRequested);
  }

  Future<void> _onDocumentUploadRequested(
    KycDocumentUploadRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    // Emit loading state with current document being uploaded
    emit(
      LoadingState<KycData>(
        message: 'Uploading ${event.documentType}...',
        progress: 0.0,
      ),
    );

    final file = File(event.filePath);

    final result = await _fileUploadUseCase.uploadFile(
      file: file,
      userId: event.userId,
      folder: 'kyc_documents/${event.documentType}',
    );

    result.fold(
      (failure) {
        emit(
          ErrorState<KycData>(
            errorMessage: failure.failureMessage,
            errorCode: 'upload_failed_${event.documentType}',
          ),
        );
      },
      (fileEntity) {
        emit(
          LoadedState<KycData>(data: KycData(currentDocument: fileEntity.url)),
        );
      },
    );
  }

  Future<void> _onFinalSubmitRequested(
    KycFinalSubmitRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    emit(
      const LoadingState<KycData>(message: 'Submitting KYC verification...'),
    );

    final result = await _kycUseCase.submitKyc(
      userId: event.userId,
      fullName: event.fullName,
      dateOfBirth: event.dateOfBirth,
      phoneNumber: event.phoneNumber,
      email: event.email,
      address: event.address,
      city: event.city,
      country: event.country,
      postalCode: event.postalCode,
      governmentIdNumber: event.governmentIdNumber,
      idType: event.idType,
      governmentIdUrl: event.governmentIdUrl,
      selfieWithIdUrl: event.selfieWithIdUrl,
      proofOfAddressUrl: event.proofOfAddressUrl,
    );

    result.fold(
      (failure) {
        emit(
          ErrorState<KycData>(
            errorMessage: failure.failureMessage,
            errorCode: 'submission_failed',
          ),
        );
      },
      (_) {
        emit(
          SuccessState<KycData>(
            successMessage:
                'KYC submitted successfully! Awaiting verification.',
          ),
        );
      },
    );
  }
}
