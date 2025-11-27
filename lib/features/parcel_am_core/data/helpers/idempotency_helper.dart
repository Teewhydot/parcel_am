import 'package:uuid/uuid.dart';

/// Utility class for generating and validating transaction idempotency keys.
///
/// Idempotency keys ensure that duplicate transaction requests are detected
/// and handled properly, preventing double-processing of operations.
class IdempotencyHelper {
  static const _uuid = Uuid();

  /// Generates a unique transaction ID in the format:
  /// `txn_{operationType}_{timestamp}_{uuid}`
  ///
  /// Parameters:
  /// - [operationType]: The type of operation (e.g., 'hold', 'release', 'deposit', 'withdrawal')
  ///
  /// Returns: A unique transaction ID string
  ///
  /// Example: `txn_hold_1732723200000_550e8400-e29b-41d4-a716-446655440000`
  static String generateTransactionId(String operationType) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    return 'txn_${operationType}_${timestamp}_$uuid';
  }

  /// Validates that a transaction ID follows the expected format.
  ///
  /// Expected format: `txn_{operationType}_{timestamp}_{uuid}`
  ///
  /// Parameters:
  /// - [id]: The transaction ID to validate
  ///
  /// Returns: `true` if the ID follows the expected format, `false` otherwise
  static bool isValidTransactionId(String id) {
    if (id.isEmpty) return false;

    final parts = id.split('_');

    // Must have at least 4 parts: txn, operationType, timestamp, and uuid (uuid may contain underscores)
    if (parts.length < 4) return false;

    // First part must be 'txn'
    if (parts[0] != 'txn') return false;

    // Second part is the operation type (any non-empty string)
    if (parts[1].isEmpty) return false;

    // Third part must be a valid timestamp (numeric)
    if (int.tryParse(parts[2]) == null) return false;

    // Remaining parts form the UUID (join in case UUID contains underscores)
    final uuid = parts.sublist(3).join('_');
    if (uuid.isEmpty) return false;

    return true;
  }
}
