/// Business constants for the ParcelAM application.
///
/// Contains configuration values related to business logic such as
/// fees, transaction statuses, and parcel workflow settings.
class BusinessConstants {
  BusinessConstants._();

  // Fees
  /// Service fee charged per parcel transaction (in NGN)
  static const double serviceFee = 150.0;

  // Parcel creation
  /// Number of steps in the parcel creation flow (0-indexed, so 4 means steps 0-3)
  static const int createParcelSteps = 4;

  /// Maximum index for parcel creation stepper (createParcelSteps - 1)
  static const int createParcelLastStepIndex = createParcelSteps - 1;

  // Transaction statuses
  /// Status values indicating a successful transaction
  static const List<String> successStatuses = [
    'success',
    'confirmed',
    'completed',
  ];

  /// Status values indicating a failed transaction
  static const List<String> failureStatuses = [
    'failed',
    'cancelled',
    'expired',
  ];

  /// Check if a status indicates success
  static bool isSuccessStatus(String status) =>
      successStatuses.contains(status.toLowerCase());

  /// Check if a status indicates failure
  static bool isFailureStatus(String status) =>
      failureStatuses.contains(status.toLowerCase());
}
