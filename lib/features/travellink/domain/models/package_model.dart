class PackageModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final double progress;
  final LocationInfo origin;
  final LocationInfo destination;
  final LocationInfo? currentLocation;
  final CarrierInfo carrier;
  final DateTime estimatedArrival;
  final DateTime createdAt;
  final String packageType;
  final double weight;
  final double price;
  final String urgency;
  final String senderId;
  final String? receiverId;
  final List<TrackingEvent> trackingEvents;
  final PaymentInfo? paymentInfo;

  PackageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.origin,
    required this.destination,
    this.currentLocation,
    required this.carrier,
    required this.estimatedArrival,
    required this.createdAt,
    required this.packageType,
    required this.weight,
    required this.price,
    required this.urgency,
    required this.senderId,
    this.receiverId,
    required this.trackingEvents,
    this.paymentInfo,
  });

  PackageModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    double? progress,
    LocationInfo? origin,
    LocationInfo? destination,
    LocationInfo? currentLocation,
    CarrierInfo? carrier,
    DateTime? estimatedArrival,
    DateTime? createdAt,
    String? packageType,
    double? weight,
    double? price,
    String? urgency,
    String? senderId,
    String? receiverId,
    List<TrackingEvent>? trackingEvents,
    PaymentInfo? paymentInfo,
  }) {
    return PackageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      currentLocation: currentLocation ?? this.currentLocation,
      carrier: carrier ?? this.carrier,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      createdAt: createdAt ?? this.createdAt,
      packageType: packageType ?? this.packageType,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      urgency: urgency ?? this.urgency,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      trackingEvents: trackingEvents ?? this.trackingEvents,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
}

class LocationInfo {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LocationInfo({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class CarrierInfo {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final String? photoUrl;
  final String vehicleType;
  final String? vehicleNumber;
  final bool isVerified;

  CarrierInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.photoUrl,
    required this.vehicleType,
    this.vehicleNumber,
    required this.isVerified,
  });
}

class TrackingEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String location;
  final String status;
  final String? icon;

  TrackingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.status,
    this.icon,
  });
}

class PaymentInfo {
  final String transactionId;
  final String status;
  final double amount;
  final double serviceFee;
  final double totalAmount;
  final String paymentMethod;
  final DateTime? paidAt;
  final bool isEscrow;
  final DateTime? escrowReleaseDate;
  final String escrowStatus;
  final DateTime? escrowHeldAt;

  PaymentInfo({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.serviceFee,
    required this.totalAmount,
    required this.paymentMethod,
    this.paidAt,
    required this.isEscrow,
    this.escrowReleaseDate,
    this.escrowStatus = 'pending',
    this.escrowHeldAt,
  });

  PaymentInfo copyWith({
    String? transactionId,
    String? status,
    double? amount,
    double? serviceFee,
    double? totalAmount,
    String? paymentMethod,
    DateTime? paidAt,
    bool? isEscrow,
    DateTime? escrowReleaseDate,
    String? escrowStatus,
    DateTime? escrowHeldAt,
  }) {
    return PaymentInfo(
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      serviceFee: serviceFee ?? this.serviceFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      isEscrow: isEscrow ?? this.isEscrow,
      escrowReleaseDate: escrowReleaseDate ?? this.escrowReleaseDate,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      escrowHeldAt: escrowHeldAt ?? this.escrowHeldAt,
    );
  }
}