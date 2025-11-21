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
  StreamSubscription<String>? _kycStatusSubscription;

  KycBloc() : super(const InitialState<KycData>()) {
    on<KycSubmitRequested>(_onSubmitRequested);
    on<KycStatusUpdated>(_onStatusUpdated);
    on<KycResubmitRequested>(_onResubmitRequested);
    on<KycDocumentUploadRequested>(_onDocumentUploadRequested);
    on<KycDocumentUploadProgressUpdated>(_onDocumentUploadProgressUpdated);
    on<KycDocumentUploadCompleted>(_onDocumentUploadCompleted);
    on<KycDocumentUploadFailed>(_onDocumentUploadFailed);
    on<KycFinalSubmitRequested>(_onFinalSubmitRequested);
  }

  /// Get current KYC data or return default
  KycData _getCurrentKycData() {
    if (state.hasData && state.data != null) {
      return state.data!;
    }
    return const KycData();
  }

  Future<void> _onSubmitRequested(
    KycSubmitRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    emit(const LoadingState<KycData>(message: 'Submitting KYC documents...'));

    // Note: This event is deprecated, kept for backward compatibility
    // New flow uses document uploads followed by final submission
    emit(const ErrorState<KycData>(
      errorMessage: 'Please use the new KYC submission flow',
      errorCode: 'deprecated_event',
    ));
  }

  void _onStatusUpdated(
    KycStatusUpdated event,
    Emitter<BaseState<KycData>> emit,
  ) {
    _emitStatusState(event.status, emit);
  }

  Future<void> _onResubmitRequested(
    KycResubmitRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    emit(const LoadingState<KycData>(message: 'Resubmitting KYC documents...'));

    // Note: This event is deprecated, kept for backward compatibility
    // New flow uses document uploads followed by final submission
    emit(const ErrorState<KycData>(
      errorMessage: 'Please use the new KYC submission flow',
      errorCode: 'deprecated_event',
    ));
  }

  void subscribeToKycStatus(String userId) {
    _kycStatusSubscription?.cancel();
    _kycStatusSubscription = _kycUseCase.watchKycStatus(userId).listen(
      (status) {
        add(KycStatusUpdated(status));
      },
    );
  }

  void _emitStatusState(String status, Emitter<BaseState<KycData>> emit) {
    final currentData = _getCurrentKycData();

    switch (status) {
      case 'not_submitted':
        emit(const InitialState<KycData>());
        break;
      case 'pending':
        emit(LoadedState<KycData>(
          data: currentData.copyWith(
            status: 'pending',
            submittedAt: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        ));
        break;
      case 'approved':
        emit(LoadedState<KycData>(
          data: currentData.copyWith(
            status: 'approved',
            approvedAt: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        ));
        break;
      case 'rejected':
        emit(LoadedState<KycData>(
          data: currentData.copyWith(
            status: 'rejected',
            rejectedAt: DateTime.now(),
            rejectionReason: 'Your KYC submission was rejected. Please resubmit with correct documents.',
          ),
          lastUpdated: DateTime.now(),
        ));
        break;
      default:
        emit(const InitialState<KycData>());
    }
  }

  Future<void> _onDocumentUploadRequested(
    KycDocumentUploadRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    final currentData = _getCurrentKycData();

    // Emit loading state with current document being uploaded
    emit(LoadingState<KycData>(
      message: 'Uploading ${event.documentType}...',
      progress: 0.0,
    ));

    try {
      final file = File(event.filePath);

      final result = await _fileUploadUseCase.uploadFile(
        file: file,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          add(KycDocumentUploadFailed(
            documentType: event.documentType,
            error: failure.failureMessage,
          ));
        },
        (fileEntity) {
          add(KycDocumentUploadCompleted(
            documentType: event.documentType,
            downloadUrl: fileEntity.url,
          ));
        },
      );
    } catch (e) {
      add(KycDocumentUploadFailed(
        documentType: event.documentType,
        error: e.toString(),
      ));
    }
  }

  void _onDocumentUploadProgressUpdated(
    KycDocumentUploadProgressUpdated event,
    Emitter<BaseState<KycData>> emit,
  ) {
    final currentData = _getCurrentKycData();
    final updatedProgress = Map<String, double>.from(currentData.uploadProgress);
    updatedProgress[event.documentType] = event.progress;

    emit(LoadingState<KycData>(
      message: 'Uploading ${event.documentType}...',
      progress: event.progress,
    ));
  }

  void _onDocumentUploadCompleted(
    KycDocumentUploadCompleted event,
    Emitter<BaseState<KycData>> emit,
  ) {
    final currentData = _getCurrentKycData();
    final updatedDocuments = Map<String, String>.from(currentData.uploadedDocuments);
    updatedDocuments[event.documentType] = event.downloadUrl;

    emit(LoadedState<KycData>(
      data: currentData.copyWith(
        uploadedDocuments: updatedDocuments,
        currentDocument: null, // Clear current document after upload
      ),
      lastUpdated: DateTime.now(),
    ));

    // Emit success message
    emit(SuccessState<KycData>(
      successMessage: '${event.documentType} uploaded successfully',
    ));

    // Return to loaded state with updated data
    emit(LoadedState<KycData>(
      data: currentData.copyWith(
        uploadedDocuments: updatedDocuments,
        currentDocument: null,
      ),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onDocumentUploadFailed(
    KycDocumentUploadFailed event,
    Emitter<BaseState<KycData>> emit,
  ) {
    emit(ErrorState<KycData>(
      errorMessage: 'Failed to upload ${event.documentType}: ${event.error}',
      errorCode: 'upload_failed',
    ));
  }

  Future<void> _onFinalSubmitRequested(
    KycFinalSubmitRequested event,
    Emitter<BaseState<KycData>> emit,
  ) async {
    emit(const LoadingState<KycData>(message: 'Submitting KYC verification...'));

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
        emit(ErrorState<KycData>(
          errorMessage: failure.failureMessage,
          errorCode: 'submission_failed',
        ));
      },
      (_) {
        final currentData = _getCurrentKycData();
        emit(SuccessState<KycData>(
          successMessage: 'KYC submitted successfully! Awaiting verification.',
        ));

        emit(LoadedState<KycData>(
          data: currentData.copyWith(
            status: 'pending',
            submittedAt: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _kycStatusSubscription?.cancel();
    return super.close();
  }
}
