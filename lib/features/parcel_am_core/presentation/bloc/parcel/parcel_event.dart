import 'package:equatable/equatable.dart';
import '../../../domain/entities/parcel_entity.dart';

abstract class ParcelEvent extends Equatable {
  const ParcelEvent();

  @override
  List<Object?> get props => [];
}

class ParcelCreateRequested extends ParcelEvent {
  final ParcelEntity parcel;

  const ParcelCreateRequested(this.parcel);

  @override
  List<Object?> get props => [parcel];
}

class ParcelUpdateStatusRequested extends ParcelEvent {
  final String parcelId;
  final ParcelStatus status;

  const ParcelUpdateStatusRequested({
    required this.parcelId,
    required this.status,
  });

  @override
  List<Object?> get props => [parcelId, status];
}

class ParcelWatchRequested extends ParcelEvent {
  final String parcelId;

  const ParcelWatchRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class ParcelWatchUserParcelsRequested extends ParcelEvent {
  final String userId;

  const ParcelWatchUserParcelsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ParcelStatusUpdated extends ParcelEvent {
  final ParcelEntity parcel;

  const ParcelStatusUpdated(this.parcel);

  @override
  List<Object?> get props => [parcel];
}

class ParcelListUpdated extends ParcelEvent {
  final List<ParcelEntity> parcels;

  const ParcelListUpdated(this.parcels);

  @override
  List<Object?> get props => [parcels];
}

class ParcelLoadRequested extends ParcelEvent {
  final String parcelId;

  const ParcelLoadRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class ParcelLoadUserParcels extends ParcelEvent {
  final String userId;

  const ParcelLoadUserParcels(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ParcelPaymentCompleted extends ParcelEvent {
  final String parcelId;
  final String transactionId;

  const ParcelPaymentCompleted({
    required this.parcelId,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [parcelId, transactionId];
}

class ParcelWatchAvailableParcelsRequested extends ParcelEvent {
  const ParcelWatchAvailableParcelsRequested();
}

class ParcelAvailableListUpdated extends ParcelEvent {
  final List<ParcelEntity> parcels;

  const ParcelAvailableListUpdated(this.parcels);

  @override
  List<Object?> get props => [parcels];
}

class ParcelAssignTravelerRequested extends ParcelEvent {
  final String parcelId;
  final String travelerId;

  const ParcelAssignTravelerRequested({
    required this.parcelId,
    required this.travelerId,
  });

  @override
  List<Object?> get props => [parcelId, travelerId];
}

/// Event to request watching parcels where the current user is the traveler.
/// This is used for the "My Deliveries" tab to show real-time updates of
/// parcels that the user has accepted for delivery.
class ParcelWatchAcceptedParcelsRequested extends ParcelEvent {
  /// The ID of the user who is the traveler (courier)
  final String userId;

  const ParcelWatchAcceptedParcelsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event emitted when the list of accepted parcels is updated from the stream.
/// This event is triggered by Firestore real-time updates and provides the
/// updated list of parcels where the user is the assigned traveler.
class ParcelAcceptedListUpdated extends ParcelEvent {
  /// The updated list of parcels where the user is the traveler
  final List<ParcelEntity> acceptedParcels;

  const ParcelAcceptedListUpdated(this.acceptedParcels);

  @override
  List<Object?> get props => [acceptedParcels];
}

/// Event for sender to confirm delivery and release payment.
///
/// This event is triggered when the sender confirms that the receiver
/// has received the parcel. Upon confirmation:
/// 1. Parcel status is updated to 'delivered'
/// 2. Escrow payment is released to the courier
///
/// Only the sender can trigger this event for their own parcels.
class ParcelConfirmDeliveryRequested extends ParcelEvent {
  /// The ID of the parcel to confirm delivery for
  final String parcelId;

  /// The ID of the escrow holding the payment
  final String escrowId;

  const ParcelConfirmDeliveryRequested({
    required this.parcelId,
    required this.escrowId,
  });

  @override
  List<Object?> get props => [parcelId, escrowId];
}

/// Event to cancel a parcel and release held balance back to available.
///
/// This event can only be triggered for parcels with status 'created' or 'paid'.
/// Upon cancellation:
/// 1. Parcel status is updated to 'cancelled'
/// 2. Held balance is released back to available balance
class ParcelCancelRequested extends ParcelEvent {
  /// The ID of the parcel to cancel
  final String parcelId;

  /// The user ID of the parcel owner (for wallet release)
  final String userId;

  /// The amount to release back to available balance
  final double amount;

  /// Optional reason for cancellation
  final String? reason;

  const ParcelCancelRequested({
    required this.parcelId,
    required this.userId,
    required this.amount,
    this.reason,
  });

  @override
  List<Object?> get props => [parcelId, userId, amount, reason];
}
