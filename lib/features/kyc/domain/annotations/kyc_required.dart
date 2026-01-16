/// Annotation to mark features/routes that require KYC verification
class KycRequired {
  /// Whether to allow access with pending KYC status
  final bool allowPending;

  /// Custom message to display when KYC is required
  final String? message;

  /// Minimum KYC level required (for future multi-level KYC)
  final int level;

  const KycRequired({
    this.allowPending = false,
    this.message,
    this.level = 1,
  });
}

/// Annotation for KYC-protected routes
const kycRequired = KycRequired();

/// Annotation for routes that allow pending KYC
const kycRequiredAllowPending = KycRequired(allowPending: true);
