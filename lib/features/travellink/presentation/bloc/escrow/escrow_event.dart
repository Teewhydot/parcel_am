import 'package:equatable/equatable.dart';

abstract class EscrowEvent extends Equatable {
  const EscrowEvent();

  @override
  List<Object?> get props => [];
}

class EscrowCreateRequested extends EscrowEvent {
  final String walletId;
  final String userId;
  final double amount;
  final String referenceId;
  final String referenceType;

  const EscrowCreateRequested({
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.referenceId,
    required this.referenceType,
  });

  @override
  List<Object?> get props =>
      [walletId, userId, amount, referenceId, referenceType];
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
