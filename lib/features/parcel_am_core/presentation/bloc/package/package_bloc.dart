import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../data/models/package_model.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';
import '../../../domain/usecases/escrow_usecase.dart';
import 'package_event.dart';
import 'package_state.dart';

class PackageBloc extends BaseBloC<PackageEvent, BaseState<PackageData>> {
  final _parcelUseCase = ParcelUseCase();
  final _escrowUseCase = EscrowUseCase();
  StreamSubscription? _packageStreamSubscription;

  PackageBloc() : super(const InitialState<PackageData>()) {
    on<PackageStreamStarted>(_onPackageStreamStarted);
    on<PackageUpdated>(_onPackageUpdated);
    on<ParcelDataReceived>(_onParcelDataReceived);
    on<ParcelLoadFailed>(_onParcelLoadFailed);
    on<EscrowReleaseRequested>(_onEscrowReleaseRequested);
    on<EscrowDisputeRequested>(_onEscrowDisputeRequested);
    on<DeliveryConfirmationRequested>(_onDeliveryConfirmationRequested);
  }

  Future<void> _onPackageStreamStarted(
    PackageStreamStarted event,
    Emitter<BaseState<PackageData>> emit,
  ) async {
    emit(const LoadingState<PackageData>());

    await _packageStreamSubscription?.cancel();

    _packageStreamSubscription = _parcelUseCase.watchParcelStatus(event.packageId).listen((result) {
      result.fold(
        (failure) {
          if (!isClosed) {
            add(ParcelLoadFailed(failure.failureMessage));
          }
        },
        (parcelEntity) {
          if (!isClosed) {
            add(ParcelDataReceived(parcelEntity));
          }
        },
      );
    });
  }

  void _onParcelDataReceived(
    ParcelDataReceived event,
    Emitter<BaseState<PackageData>> emit,
  ) {
    final parcelEntity = event.parcelEntity as ParcelEntity;
    final package = _convertToPackageEntity(parcelEntity);
    final currentData = state.data ?? const PackageData();

    emit(LoadedState<PackageData>(
      data: currentData.copyWith(package: package),
      lastUpdated: DateTime.now(),
    ));
  }

  void _onParcelLoadFailed(
    ParcelLoadFailed event,
    Emitter<BaseState<PackageData>> emit,
  ) {
    emit(ErrorState<PackageData>(
      errorMessage: event.errorMessage,
    ));
  }

  void _onPackageUpdated(
    PackageUpdated event,
    Emitter<BaseState<PackageData>> emit,
  ) {
    final package = PackageModel.fromJson(event.packageData);
    final currentData = state.data ?? const PackageData();

    emit(LoadedState<PackageData>(
      data: currentData.copyWith(package: package),
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onEscrowReleaseRequested(
    EscrowReleaseRequested event,
    Emitter<BaseState<PackageData>> emit,
  ) async {
    final currentData = state.data ?? const PackageData();

    emit(AsyncLoadingState<PackageData>(
      data: currentData.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.processing,
        escrowMessage: 'Processing escrow release...',
      ),
    ));

    final result = await _escrowUseCase.releaseEscrow(event.transactionId);

    result.fold(
      (failure) => emit(LoadedState<PackageData>(
        data: currentData.copyWith(
          escrowReleaseStatus: EscrowReleaseStatus.failed,
          escrowMessage: 'Failed to release escrow: ${failure.failureMessage}',
        ),
        lastUpdated: DateTime.now(),
      )),
      (_) => emit(LoadedState<PackageData>(
        data: currentData.copyWith(
          escrowReleaseStatus: EscrowReleaseStatus.released,
          escrowMessage: 'Escrow funds released successfully',
        ),
        lastUpdated: DateTime.now(),
      )),
    );
  }

  Future<void> _onEscrowDisputeRequested(
    EscrowDisputeRequested event,
    Emitter<BaseState<PackageData>> emit,
  ) async {
    final currentData = state.data ?? const PackageData();

    emit(AsyncLoadingState<PackageData>(
      data: currentData.copyWith(
        escrowReleaseStatus: EscrowReleaseStatus.processing,
        escrowMessage: 'Filing dispute...',
      ),
    ));

    final result = await _escrowUseCase.cancelEscrow(
      event.transactionId,
      event.reason,
    );

    result.fold(
      (failure) => emit(LoadedState<PackageData>(
        data: currentData.copyWith(
          escrowReleaseStatus: EscrowReleaseStatus.failed,
          escrowMessage: 'Failed to file dispute: ${failure.failureMessage}',
        ),
        lastUpdated: DateTime.now(),
      )),
      (escrow) => emit(LoadedState<PackageData>(
        data: currentData.copyWith(
          escrowReleaseStatus: EscrowReleaseStatus.disputed,
          escrowMessage: 'Dispute filed successfully',
          disputeId: escrow.id,
        ),
        lastUpdated: DateTime.now(),
      )),
    );
  }

  Future<void> _onDeliveryConfirmationRequested(
    DeliveryConfirmationRequested event,
    Emitter<BaseState<PackageData>> emit,
  ) async {
    final currentData = state.data ?? const PackageData();

    emit(AsyncLoadingState<PackageData>(data: currentData));

    final result = await _parcelUseCase.updateParcelStatus(
      event.packageId,
      ParcelStatus.delivered,
    );

    result.fold(
      (failure) => emit(AsyncErrorState<PackageData>(
        errorMessage: 'Failed to confirm delivery: ${failure.failureMessage}',
        data: currentData,
      )),
      (_) => emit(LoadedState<PackageData>(
        data: currentData.copyWith(
          deliveryConfirmed: true,
          escrowMessage: 'Delivery confirmed successfully',
        ),
        lastUpdated: DateTime.now(),
      )),
    );
  }

  /// Converts ParcelEntity to PackageEntity for tracking screen compatibility
  PackageEntity _convertToPackageEntity(ParcelEntity parcel) {
    final trackingEvents = <TrackingEventEntity>[];
    final statusHistory = parcel.metadata?['deliveryStatusHistory'] as Map<String, dynamic>?;
    if (statusHistory != null) {
      statusHistory.forEach((status, timestamp) {
        trackingEvents.add(TrackingEventEntity(
          id: '${parcel.id}_$status',
          title: _getEventTitle(status),
          description: _getEventDescription(status),
          timestamp: DateTime.tryParse(timestamp.toString()) ?? parcel.createdAt,
          location: status == 'created' ? parcel.route.origin : parcel.route.destination,
          status: 'completed',
        ));
      });
      trackingEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    if (trackingEvents.isEmpty || trackingEvents.last.title != _getEventTitle(parcel.status.toJson())) {
      trackingEvents.add(TrackingEventEntity(
        id: '${parcel.id}_current',
        title: _getEventTitle(parcel.status.toJson()),
        description: _getEventDescription(parcel.status.toJson()),
        timestamp: parcel.lastStatusUpdate ?? parcel.updatedAt ?? DateTime.now(),
        location: parcel.route.destination,
        status: 'current',
      ));
    }

    return PackageEntity(
      id: parcel.id,
      title: parcel.category ?? 'Package',
      description: parcel.description ?? '',
      status: parcel.status.toJson(),
      progress: _calculateProgress(parcel.status),
      origin: LocationEntity(
        name: parcel.route.origin,
        address: parcel.sender.address,
        latitude: parcel.route.originLat ?? 0.0,
        longitude: parcel.route.originLng ?? 0.0,
      ),
      destination: LocationEntity(
        name: parcel.route.destination,
        address: parcel.receiver.address,
        latitude: parcel.route.destinationLat ?? 0.0,
        longitude: parcel.route.destinationLng ?? 0.0,
      ),
      carrier: CarrierEntity(
        id: parcel.travelerId ?? '',
        name: parcel.travelerName ?? 'Carrier',
        phone: '',
        rating: 4.5,
        vehicleType: 'car',
        isVerified: true,
      ),
      estimatedArrival: parcel.route.estimatedDeliveryDate != null
          ? DateTime.tryParse(parcel.route.estimatedDeliveryDate!) ?? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: parcel.createdAt,
      packageType: parcel.category ?? 'General',
      weight: parcel.weight ?? 0.0,
      price: parcel.price ?? 0.0,
      urgency: 'Normal',
      senderId: parcel.sender.userId,
      trackingEvents: trackingEvents,
      paymentInfo: parcel.escrowId != null
          ? PaymentEntity(
              transactionId: parcel.escrowId!,
              status: 'completed',
              amount: parcel.price ?? 0.0,
              serviceFee: 150.0,
              totalAmount: (parcel.price ?? 0.0) + 150.0,
              paymentMethod: 'escrow',
              isEscrow: true,
              escrowStatus: parcel.status == ParcelStatus.delivered ? 'released' : 'held',
              escrowHeldAt: parcel.createdAt,
            )
          : null,
    );
  }

  double _calculateProgress(ParcelStatus status) {
    return switch (status) {
      ParcelStatus.created => 10.0,
      ParcelStatus.paid => 20.0,
      ParcelStatus.pickedUp => 40.0,
      ParcelStatus.inTransit => 60.0,
      ParcelStatus.arrived => 80.0,
      ParcelStatus.awaitingConfirmation => 90.0,
      ParcelStatus.delivered => 100.0,
      ParcelStatus.cancelled => 0.0,
      ParcelStatus.disputed => 0.0,
    };
  }

  String _getEventTitle(String status) {
    return switch (status) {
      'created' => 'Package Created',
      'paid' => 'Payment Confirmed',
      'picked_up' => 'Package Picked Up',
      'in_transit' => 'In Transit',
      'arrived' => 'Arrived at Destination',
      'awaiting_confirmation' => 'Awaiting Confirmation',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      'disputed' => 'Disputed',
      _ => status,
    };
  }

  String _getEventDescription(String status) {
    return switch (status) {
      'created' => 'Your package request has been created',
      'paid' => 'Payment has been confirmed and held in escrow',
      'picked_up' => 'Carrier has picked up your package',
      'in_transit' => 'Your package is on the way',
      'arrived' => 'Package has arrived at the destination city',
      'awaiting_confirmation' => 'Waiting for delivery confirmation',
      'delivered' => 'Package has been delivered successfully',
      'cancelled' => 'Package delivery has been cancelled',
      'disputed' => 'A dispute has been filed',
      _ => 'Status updated',
    };
  }

  @override
  Future<void> close() {
    _packageStreamSubscription?.cancel();
    return super.close();
  }
}
