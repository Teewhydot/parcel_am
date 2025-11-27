class WalletException implements Exception {
  final String message;

  const WalletException(this.message);

  @override
  String toString() => message;
}

class InsufficientBalanceException extends WalletException {
  const InsufficientBalanceException()
      : super('Insufficient balance for this operation');
}

class InsufficientHeldBalanceException extends WalletException {
  final double required;
  final double available;

  const InsufficientHeldBalanceException({
    required this.required,
    required this.available,
  }) : super('Insufficient held balance. Required: $required, Available: $available');
}

class WalletNotFoundException extends WalletException {
  const WalletNotFoundException() : super('Wallet not found');
}

class InvalidAmountException extends WalletException {
  const InvalidAmountException() : super('Invalid amount specified');
}

class TransactionFailedException extends WalletException {
  const TransactionFailedException([String? message])
      : super(message ?? 'Transaction failed');
}

class HoldBalanceFailedException extends WalletException {
  const HoldBalanceFailedException([String? message])
      : super(message ?? 'Failed to hold balance');
}

class ReleaseBalanceFailedException extends WalletException {
  const ReleaseBalanceFailedException([String? message])
      : super(message ?? 'Failed to release balance');
}
