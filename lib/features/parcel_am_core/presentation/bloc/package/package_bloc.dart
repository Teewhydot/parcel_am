import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/package_model.dart';
import '../../../../package/domain/usecases/watch_package.dart';
import '../../../../package/domain/usecases/release_escrow.dart';
import '../../../../package/domain/usecases/create_dispute.dart';
import '../../../../package/domain/usecases/confirm_delivery.dart';
import 'package_event.dart';
import 'package_state.dart';

class PackageBloc extends Bloc<PackageEvent, PackageState> {
  final _watchPackage = WatchPackage();
  final _releaseEscrow = ReleaseEscrow();
  final _createDispute = CreateDispute();
  final _confirmDelivery = ConfirmDelivery();
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

    _packageStreamSubscription = _watchPackage(event.packageId).listen((result) {
      result.fold(
        (failure) {
          if (!isClosed) {
            emit(state.copyWith(
              isLoading: false,
              error: failure.failureMessage,
            ));
          }
        },
        (packageEntity) {
          // Package tracking migration in progress
          if (!isClosed) {
            emit(state.copyWith(
              isLoading: false,
              error: 'Package tracking migration in progress',
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

    final result = await _releaseEscrow(
      packageId: event.packageId,
      transactionId: event.transactionId,
    );

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

    final result = await _createDispute(
      packageId: event.packageId,
      transactionId: event.transactionId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.failed,
        escrowMessage: 'Failed to file dispute: ${failure.failureMessage}',
      )),
      (disputeId) => emit(state.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.disputed,
        escrowMessage: 'Dispute filed successfully',
        disputeId: disputeId,
      )),
    );
  }

  Future<void> _onDeliveryConfirmationRequested(
    DeliveryConfirmationRequested event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _confirmDelivery(
      packageId: event.packageId,
      confirmationCode: event.confirmationCode,
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
