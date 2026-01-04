import 'package:equatable/equatable.dart';
import '../../../../core/constants/business_constants.dart';

/// Entity representing a wallet funding order.
class FundingOrderEntity extends Equatable {
  final String id;
  final String reference;
  final String userId;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FundingOrderEntity({
    required this.id,
    required this.reference,
    required this.userId,
    required this.amount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the funding order completed successfully
  bool get isSuccess => BusinessConstants.isSuccessStatus(status);

  /// Whether the funding order failed
  bool get isFailed => BusinessConstants.isFailureStatus(status);

  /// Whether the funding order is still pending
  bool get isPending => !isSuccess && !isFailed;

  /// Whether the funding order has a terminal status (success or failure)
  bool get isTerminal => isSuccess || isFailed;

  @override
  List<Object?> get props => [
        id,
        reference,
        userId,
        amount,
        status,
        createdAt,
        updatedAt,
      ];
}
