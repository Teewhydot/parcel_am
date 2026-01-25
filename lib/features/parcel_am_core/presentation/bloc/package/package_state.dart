import 'package:equatable/equatable.dart';
import '../../../domain/entities/package_entity.dart';

/// Data class holding all package-related state
class PackageData extends Equatable {
  final PackageEntity? package;
  final EscrowReleaseStatus escrowReleaseStatus;
  final String? escrowMessage;
  final bool deliveryConfirmed;
  final String? disputeId;

  const PackageData({
    this.package,
    this.escrowReleaseStatus = EscrowReleaseStatus.idle,
    this.escrowMessage,
    this.deliveryConfirmed = false,
    this.disputeId,
  });

  PackageData copyWith({
    PackageEntity? package,
    EscrowReleaseStatus? escrowReleaseStatus,
    String? escrowMessage,
    bool? deliveryConfirmed,
    String? disputeId,
  }) {
    return PackageData(
      package: package ?? this.package,
      escrowReleaseStatus: escrowReleaseStatus ?? this.escrowReleaseStatus,
      escrowMessage: escrowMessage,
      deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
      disputeId: disputeId,
    );
  }

  @override
  List<Object?> get props => [
        package,
        escrowReleaseStatus,
        escrowMessage,
        deliveryConfirmed,
        disputeId,
      ];
}

enum EscrowReleaseStatus {
  idle,
  processing,
  released,
  failed,
  disputed,
}
