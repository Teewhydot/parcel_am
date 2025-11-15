import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/package_entity.dart';
import '../../domain/usecases/watch_package.dart';
import '../../domain/usecases/release_escrow.dart';
import '../../domain/usecases/create_dispute.dart';
import '../../domain/usecases/confirm_delivery.dart';

// Events
abstract class PackageEvent extends Equatable {
  const PackageEvent();

  @override
  List<Object?> get props => [];
}

class PackageStreamStarted extends PackageEvent {
  final String packageId;

  const PackageStreamStarted(this.packageId);

  @override
  List<Object?> get props => [packageId];
}

class EscrowReleaseRequested extends PackageEvent {
  final String packageId;
  final String transactionId;

  const EscrowReleaseRequested({
    required this.packageId,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [packageId, transactionId];
}

class EscrowDisputeRequested extends PackageEvent {
  final String packageId;
  final String transactionId;
  final String reason;

  const EscrowDisputeRequested({
    required this.packageId,
    required this.transactionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [packageId, transactionId, reason];
}

class DeliveryConfirmationRequested extends PackageEvent {
  final String packageId;
  final String confirmationCode;

  const DeliveryConfirmationRequested({
    required this.packageId,
    required this.confirmationCode,
  });

  @override
  List<Object?> get props => [packageId, confirmationCode];
}

// States
class PackageState extends Equatable {
  final bool isLoading;
  final PackageEntity? package;
  final String? error;
  final EscrowReleaseStatus escrowReleaseStatus;
  final String? escrowMessage;
  final bool deliveryConfirmed;
  final String? disputeId;

  const PackageState({
    this.isLoading = false,
    this.package,
    this.error,
    this.escrowReleaseStatus = EscrowReleaseStatus.idle,
    this.escrowMessage,
    this.deliveryConfirmed = false,
    this.disputeId,
  });

  PackageState copyWith({
    bool? isLoading,
    PackageEntity? package,
    String? error,
    EscrowReleaseStatus? escrowReleaseStatus,
    String? escrowMessage,
    bool? deliveryConfirmed,
    String? disputeId,
  }) {
    return PackageState(
      isLoading: isLoading ?? this.isLoading,
      package: package ?? this.package,
      error: error,
      escrowReleaseStatus: escrowReleaseStatus ?? this.escrowReleaseStatus,
      escrowMessage: escrowMessage,
      deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
      disputeId: disputeId,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        package,
        error,
        escrowReleaseStatus,
        escrowMessage,
        deliveryConfirmed,
        disputeId,
      ];
}

enum EscrowReleaseStatus {
  idle,
  processing,
  released,
  failed,
  disputed,
}

// BLoC
class PackageBloc extends Bloc<PackageEvent, PackageState> {
  final WatchPackage watchPackage;
  final ReleaseEscrow releaseEscrow;
  final CreateDispute createDispute;
  final ConfirmDelivery confirmDelivery;

  StreamSubscription? _packageSubscription;

  PackageBloc({
    required this.watchPackage,
    required this.releaseEscrow,
    required this.createDispute,
    required this.confirmDelivery,
  }) : super(const PackageState()) {
    on<PackageStreamStarted>(_onPackageStreamStarted);
    on<EscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<EscrowDisputeRequested>(_onEscrowDisputeRequested);
    on<DeliveryConfirmationRequested>(_onDeliveryConfirmationRequested);
  }

  Future<void> _onPackageStreamStarted(
    PackageStreamStarted event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    await _packageSubscription?.cancel();

    _packageSubscription = watchPackage(event.packageId).listen(
      (result) {
        result.fold(
          (failure) {
            if (!isClosed) {
              emit(state.copyWith(
                isLoading: false,
                error: failure.failureMessage,
              ));
            }
          },
          (package) {
            if (!isClosed) {
              emit(state.copyWith(
                isLoading: false,
                package: package,
                error: null,
              ));
            }
          },
        );
      },
    );
  }

  Future<void> _onEscrowReleaseRequested(
    EscrowReleaseRequested event,
    Emitter<PackageState> emit,
  ) async {
    emit(state.copyWith(
      escrowReleaseStatus: EscrowReleaseStatus.processing,
      escrowMessage: 'Processing escrow release...',
    ));

    final result = await releaseEscrow(
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

    final result = await createDispute(
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

    final result = await confirmDelivery(
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
    _packageSubscription?.cancel();
    return super.close();
  }
}
