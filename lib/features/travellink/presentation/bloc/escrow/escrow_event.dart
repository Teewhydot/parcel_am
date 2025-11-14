import 'package:equatable/equatable.dart';

abstract class EscrowEvent extends Equatable {
  const EscrowEvent();

  @override
  List<Object?> get props => [];
}

class EscrowCreateRequested extends EscrowEvent {
  final String parcelId;
  final String senderId;
  final String travelerId;
  final double amount;
  final String currency;

  const EscrowCreateRequested({
    required this.parcelId,
    required this.senderId,
    required this.travelerId,
    required this.amount,
    this.currency = 'NGN',
  });

  @override
  List<Object?> get props =>
      [parcelId, senderId, travelerId, amount, currency];
}

class EscrowHoldRequested extends EscrowEvent {
  final String escrowId;

  const EscrowHoldRequested(this.escrowId);

  @override
  List<Object?> get props => [escrowId];
}

class EscrowReleaseRequested extends EscrowEvent {
  final String escrowId;

  const EscrowReleaseRequested(this.escrowId);

  @override
  List<Object?> get props => [escrowId];
}

class EscrowCancelRequested extends EscrowEvent {
  final String escrowId;
  final String reason;

  const EscrowCancelRequested({
    required this.escrowId,
    required this.reason,
  });

  @override
  List<Object?> get props => [escrowId, reason];
}

class EscrowWatchRequested extends EscrowEvent {
  final String escrowId;

  const EscrowWatchRequested(this.escrowId);

  @override
  List<Object?> get props => [escrowId];
}

class EscrowStatusUpdated extends EscrowEvent {
  final String escrowId;

  const EscrowStatusUpdated(this.escrowId);

  @override
  List<Object?> get props => [escrowId];
}

class EscrowLoadUserEscrows extends EscrowEvent {
  final String userId;

  const EscrowLoadUserEscrows(this.userId);

  @override
  List<Object?> get props => [userId];
}
