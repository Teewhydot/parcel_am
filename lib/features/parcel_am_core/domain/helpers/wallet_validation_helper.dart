/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult(isValid: false, errorMessage: message);
  }
}

/// Helper class for wallet-related validation logic at the UI level
class WalletValidationHelper {
  /// Validates that the amount is positive (greater than zero)
  static ValidationResult validateAmountPositive(double amount) {
    if (amount <= 0) {
      return ValidationResult.invalid(
        'Amount must be greater than zero',
      );
    }
    return ValidationResult.valid();
  }

  /// Validates that there is sufficient available balance for an operation
  static ValidationResult validateSufficientBalance({
    required double required,
    required double available,
  }) {
    if (available < required) {
      return ValidationResult.invalid(
        'Insufficient available balance. Required: $required, Available: $available',
      );
    }
    return ValidationResult.valid();
  }

  /// Validates that there is sufficient held balance for a release operation
  static ValidationResult validateSufficientHeldBalance({
    required double required,
    required double held,
  }) {
    if (held < required) {
      return ValidationResult.invalid(
        'Insufficient pending balance. Required: $required, Available: $held',
      );
    }
    return ValidationResult.valid();
  }
}
