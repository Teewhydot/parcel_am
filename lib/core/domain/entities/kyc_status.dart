/// KYC (Know Your Customer) verification status enum
/// Represents the various states of user identity verification
enum KycStatus {
  notStarted,
  incomplete,
  pending,
  underReview,
  approved,
  rejected;

  /// Returns a user-friendly display name for the status
  String get displayName {
    switch (this) {
      case KycStatus.notStarted:
        return 'Not Started';
      case KycStatus.incomplete:
        return 'Incomplete';
      case KycStatus.pending:
        return 'Pending';
      case KycStatus.underReview:
        return 'Under Review';
      case KycStatus.approved:
        return 'Approved';
      case KycStatus.rejected:
        return 'Rejected';
    }
  }

  /// Converts the status to a JSON-compatible string
  String toJson() {
    switch (this) {
      case KycStatus.notStarted:
        return 'not_started';
      case KycStatus.incomplete:
        return 'incomplete';
      case KycStatus.pending:
        return 'pending';
      case KycStatus.underReview:
        return 'under_review';
      case KycStatus.approved:
        return 'approved';
      case KycStatus.rejected:
        return 'rejected';
    }
  }

  /// Creates a KycStatus from a string value
  static KycStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'not_started':
      case 'notstarted':
      case 'not_submitted':
        return KycStatus.notStarted;
      case 'incomplete':
        return KycStatus.incomplete;
      case 'pending':
        return KycStatus.pending;
      case 'under_review':
      case 'underreview':
        return KycStatus.underReview;
      case 'approved':
      case 'verified':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.notStarted;
    }
  }

  /// Returns true if the user is verified (KYC approved)
  bool get isVerified => this == KycStatus.approved;

  /// Returns true if the user needs to take action on their KYC
  bool get requiresAction =>
      this == KycStatus.notStarted ||
      this == KycStatus.incomplete ||
      this == KycStatus.rejected;
}
