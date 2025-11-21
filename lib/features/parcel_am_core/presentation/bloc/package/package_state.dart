import '../../../domain/entities/package_entity.dart';

class PackageState {
  final bool isLoading;
  final PackageEntity? package;
  final String? error;
  final EscrowReleaseStatus? escrowReleaseStatus;
  final String? escrowMessage;
  final bool deliveryConfirmed;
  final String? disputeId;

  const PackageState({
    this.isLoading = false,
    this.package,
    this.error,
    this.escrowReleaseStatus,
    this.escrowMessage,
    this.deliveryConfirmed = false,
    this.disputeId,
  });

  PackageState copyWith({
    bool? isLoading,
    PackageEntity? package,
    String? error,
    EscrowReleaseStatus? escrowReleaseStatus,
    String? escrowMessage,
    bool? deliveryConfirmed,
    String? disputeId,
  }) {
    return PackageState(
      isLoading: isLoading ?? this.isLoading,
      package: package ?? this.package,
      error: error,
      escrowReleaseStatus: escrowReleaseStatus ?? this.escrowReleaseStatus,
      escrowMessage: escrowMessage,
      deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
      disputeId: disputeId,
    );
  }
}

enum EscrowReleaseStatus {
  idle,
  processing,
  released,
  failed,
  disputed,
}
