abstract class PackageEvent {
  const PackageEvent();
}

class PackageTrackingRequested extends PackageEvent {
  final String packageId;
  
  const PackageTrackingRequested(this.packageId);
}

class PackageStreamStarted extends PackageEvent {
  final String packageId;
  
  const PackageStreamStarted(this.packageId);
}

class PackageUpdated extends PackageEvent {
  final Map<String, dynamic> packageData;
  
  const PackageUpdated(this.packageData);
}

class EscrowReleaseRequested extends PackageEvent {
  final String packageId;
  final String transactionId;
  
  const EscrowReleaseRequested({
    required this.packageId,
    required this.transactionId,
  });
}

class EscrowDisputeRequested extends PackageEvent {
  final String packageId;
  final String transactionId;
  final String reason;
  
  const EscrowDisputeRequested({
    required this.packageId,
    required this.transactionId,
    required this.reason,
  });
}

class DeliveryConfirmationRequested extends PackageEvent {
  final String packageId;
  final String confirmationCode;

  const DeliveryConfirmationRequested({
    required this.packageId,
    required this.confirmationCode,
  });
}

class ParcelDataReceived extends PackageEvent {
  final dynamic parcelEntity;

  const ParcelDataReceived(this.parcelEntity);
}

class ParcelLoadFailed extends PackageEvent {
  final String errorMessage;

  const ParcelLoadFailed(this.errorMessage);
}
