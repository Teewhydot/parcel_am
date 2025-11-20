import 'package:equatable/equatable.dart';

abstract class PaystackPaymentEvent extends Equatable {
  const PaystackPaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize wallet funding via Paystack
class InitializePaystackPaymentEvent extends PaystackPaymentEvent {
  final String transactionId;
  final double amount;
  final String email;
  final Map<String, dynamic>? metadata;

  const InitializePaystackPaymentEvent({
    required this.transactionId,
    required this.amount,
    required this.email,
    this.metadata,
  });

  @override
  List<Object?> get props => [transactionId, amount, email, metadata];
}

/// Event to verify wallet funding payment
class VerifyPaystackPaymentEvent extends PaystackPaymentEvent {
  final String reference;
  final String transactionId;

  const VerifyPaystackPaymentEvent({
    required this.reference,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [reference, transactionId];
}

class GetTransactionStatusEvent extends PaystackPaymentEvent {
  final String reference;

  const GetTransactionStatusEvent({
    required this.reference,
  });

  @override
  List<Object?> get props => [reference];
}

class ClearPaystackPaymentEvent extends PaystackPaymentEvent {
  const ClearPaystackPaymentEvent();
}