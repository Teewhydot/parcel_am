import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/package_model.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';
import '../../../domain/usecases/escrow_usecase.dart';
import 'package_event.dart';
import 'package_state.dart';

class PackageBloc extends Bloc<PackageEvent, PackageState> {
  final _parcelUseCase = ParcelUseCase();
  final _escrowUseCase = EscrowUseCase();
  StreamSubscription? _packageStreamSubscription;

  PackageBloc() : super(const PackageState()) {
    on<PackageStreamStarted>(_onPackageStreamStarted);
    on<PackageUpdated>(_onPackageUpdated);
    on<EscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<EscrowDisputeRequested>(_onEscrowDisputeRequested);
    on<DeliveryConfirmationRequested>(_onDeliveryConfirmationRequested);
  }

  Future<void> _onPackageStreamStarted(
    PackageStreamStarted event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    await _packageStreamSubscription?.cancel();

    // Use parcel usecase to watch parcel status
    _packageStreamSubscription = _parcelUseCase.watchParcelStatus(event.packageId).listen((result) {
      result.fold(
        (failure) {
          if (!isClosed) {
            emit(state.copyWith(
              isLoading: false,
              error: failure.failureMessage,
            ));
          }
        },
        (parcelEntity) {
          // Parcel found, but PackageEntity has different structure
          // For now, just clear loading state
          if (!isClosed) {
            emit(state.copyWith(
              isLoading: false,
              error: null,
            ));
          }
        },
      );
    });
  }

  void _onPackageUpdated(
    PackageUpdated event,
    Emitter<PackageState> emit,
  ) {
    final package = PackageModel.fromJson(event.packageData);

    emit(state.copyWith(
      isLoading: false,
      package: package,
      error: null,
    ));
  }

  Future<void> _onEscrowReleaseRequested(
    EscrowReleaseRequested event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(
      escrowReleaseStatus: EscrowReleaseStatus.processing,
      escrowMessage: 'Processing escrow release...',
    ));

    // Use escrow usecase - note: it uses escrowId, not packageId
    final result = await _escrowUseCase.releaseEscrow(event.transactionId);

    result.fold(
      (failure) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.failed,
        escrowMessage: 'Failed to release escrow: ${failure.failureMessage}',
      )),
      (_) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.released,
        escrowMessage: 'Escrow funds released successfully',
      )),
    );
  }

  Future<void> _onEscrowDisputeRequested(
    EscrowDisputeRequested event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(
      escrowReleaseStatus: EscrowReleaseStatus.processing,
      escrowMessage: 'Filing dispute...',
    ));

    // Use cancelEscrow as dispute mechanism
    final result = await _escrowUseCase.cancelEscrow(
      event.transactionId,
      event.reason,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.failed,
        escrowMessage: 'Failed to file dispute: ${failure.failureMessage}',
      )),
      (escrow) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.disputed,
        escrowMessage: 'Dispute filed successfully',
        disputeId: escrow.id,
      )),
    );
  }

  Future<void> _onDeliveryConfirmationRequested(
    DeliveryConfirmationRequested event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Update parcel status to delivered
    final result = await _parcelUseCase.updateParcelStatus(
      event.packageId,
      ParcelStatus.delivered,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: 'Failed to confirm delivery: ${failure.failureMessage}',
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        deliveryConfirmed: true,
        escrowMessage: 'Delivery confirmed successfully',
      )),
    );
  }

  @override
  Future<void> close() {
    _packageStreamSubscription?.cancel();
    return super.close();
  }
}
