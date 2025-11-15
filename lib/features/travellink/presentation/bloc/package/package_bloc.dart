import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/package_model.dart';
import '../../../../package/domain/usecases/watch_package.dart';
import '../../../../package/domain/usecases/release_escrow.dart';
import '../../../../package/domain/usecases/create_dispute.dart';
import '../../../../package/domain/usecases/confirm_delivery.dart';
import 'package_event.dart';
import 'package_state.dart';

class PackageBloc extends Bloc<PackageEvent, PackageState> {
  final WatchPackage _watchPackage;
  final ReleaseEscrow _releaseEscrow;
  final CreateDispute _createDispute;
  final ConfirmDelivery _confirmDelivery;
  StreamSubscription? _packageStreamSubscription;

  PackageBloc({
    required WatchPackage watchPackage,
    required ReleaseEscrow releaseEscrow,
    required CreateDispute createDispute,
    required ConfirmDelivery confirmDelivery,
  })  : _watchPackage = watchPackage,
        _releaseEscrow = releaseEscrow,
        _createDispute = createDispute,
        _confirmDelivery = confirmDelivery,
        super(const PackageState()) {
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
          // For now, we need to fetch the full package data from repository
          // This is a temporary solution until we properly migrate PackageModel to entity
          // TODO: Refactor PackageModel to be a proper domain entity
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
    final packageData = event.packageData;
    final package = PackageModel(
      id: packageData['id'] ?? '',
      title: packageData['title'] ?? '',
      description: packageData['description'] ?? '',
      status: packageData['status'] ?? 'pending',
      progress: (packageData['progress'] ?? 0).toDouble(),
      origin: _parseLocationInfo(packageData['origin']),
      destination: _parseLocationInfo(packageData['destination']),
      currentLocation: packageData['currentLocation'] != null
          ? _parseLocationInfo(packageData['currentLocation'])
          : null,
      carrier: _parseCarrierInfo(packageData['carrier']),
      estimatedArrival: packageData['estimatedArrival'] != null
          ? DateTime.parse(packageData['estimatedArrival'])
          : DateTime.now(),
      createdAt: packageData['createdAt'] != null
          ? DateTime.parse(packageData['createdAt'])
          : DateTime.now(),
      packageType: packageData['packageType'] ?? '',
      weight: (packageData['weight'] ?? 0).toDouble(),
      price: (packageData['price'] ?? 0).toDouble(),
      urgency: packageData['urgency'] ?? 'normal',
      senderId: packageData['senderId'] ?? '',
      receiverId: packageData['receiverId'],
      trackingEvents: (packageData['trackingEvents'] as List?)
              ?.map((e) => _parseTrackingEvent(e))
              .toList() ??
          [],
      paymentInfo: packageData['paymentInfo'] != null
          ? _parsePaymentInfo(packageData['paymentInfo'])
          : null,
    );

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

  LocationInfo _parseLocationInfo(Map<String, dynamic> data) {
    return LocationInfo(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
    );
  }

  CarrierInfo _parseCarrierInfo(Map<String, dynamic> data) {
    return CarrierInfo(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      photoUrl: data['photoUrl'],
      vehicleType: data['vehicleType'] ?? '',
      vehicleNumber: data['vehicleNumber'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  TrackingEvent _parseTrackingEvent(Map<String, dynamic> data) {
    return TrackingEvent(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      location: data['location'] ?? '',
      status: data['status'] ?? '',
      icon: data['icon'],
    );
  }

  PaymentInfo _parsePaymentInfo(Map<String, dynamic> data) {
    return PaymentInfo(
      transactionId: data['transactionId'] ?? '',
      status: data['status'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      paidAt: data['paidAt'] != null ? DateTime.parse(data['paidAt']) : null,
      isEscrow: data['isEscrow'] ?? false,
      escrowReleaseDate: data['escrowReleaseDate'] != null
          ? DateTime.parse(data['escrowReleaseDate'])
          : null,
      escrowStatus: data['escrowStatus'] ?? 'pending',
      escrowHeldAt: data['escrowHeldAt'] != null
          ? DateTime.parse(data['escrowHeldAt'])
          : null,
    );
  }

  @override
  Future<void> close() {
    _packageStreamSubscription?.cancel();
    return super.close();
  }
}
