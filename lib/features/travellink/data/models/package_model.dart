import '../../domain/entities/package_entity.dart';

class PackageModel extends PackageEntity {
  const PackageModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.progress,
    required super.origin,
    required super.destination,
    super.currentLocation,
    required super.carrier,
    required super.estimatedArrival,
    required super.createdAt,
    required super.packageType,
    required super.weight,
    required super.price,
    required super.urgency,
    required super.senderId,
    super.receiverId,
    required super.trackingEvents,
    super.paymentInfo,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      progress: (json['progress'] ?? 0).toDouble(),
      origin: LocationModel.fromJson(json['origin']),
      destination: LocationModel.fromJson(json['destination']),
      currentLocation: json['currentLocation'] != null
          ? LocationModel.fromJson(json['currentLocation'])
          : null,
      carrier: CarrierModel.fromJson(json['carrier']),
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      packageType: json['packageType'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      urgency: json['urgency'] ?? 'normal',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'],
      trackingEvents: (json['trackingEvents'] as List?)
              ?.map((e) => TrackingEventModel.fromJson(e))
              .toList() ??
          [],
      paymentInfo: json['paymentInfo'] != null
          ? PaymentModel.fromJson(json['paymentInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'progress': progress,
      'origin': (origin as LocationModel).toJson(),
      'destination': (destination as LocationModel).toJson(),
      'currentLocation': (currentLocation as LocationModel?)?.toJson(),
      'carrier': (carrier as CarrierModel).toJson(),
      'estimatedArrival': estimatedArrival.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'packageType': packageType,
      'weight': weight,
      'price': price,
      'urgency': urgency,
      'senderId': senderId,
      'receiverId': receiverId,
      'trackingEvents': trackingEvents
          .map((e) => (e as TrackingEventModel).toJson())
          .toList(),
      'paymentInfo': (paymentInfo as PaymentModel?)?.toJson(),
    };
  }
}

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class CarrierModel extends CarrierEntity {
  const CarrierModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.rating,
    super.photoUrl,
    required super.vehicleType,
    super.vehicleNumber,
    required super.isVerified,
  });

  factory CarrierModel.fromJson(Map<String, dynamic> json) {
    return CarrierModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      photoUrl: json['photoUrl'],
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'rating': rating,
      'photoUrl': photoUrl,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'isVerified': isVerified,
    };
  }
}

class TrackingEventModel extends TrackingEventEntity {
  const TrackingEventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.timestamp,
    required super.location,
    required super.status,
    super.icon,
  });

  factory TrackingEventModel.fromJson(Map<String, dynamic> json) {
    return TrackingEventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'status': status,
      'icon': icon,
    };
  }
}

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.transactionId,
    required super.status,
    required super.amount,
    required super.serviceFee,
    required super.totalAmount,
    required super.paymentMethod,
    super.paidAt,
    required super.isEscrow,
    super.escrowReleaseDate,
    super.escrowStatus = 'pending',
    super.escrowHeldAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      transactionId: json['transactionId'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      serviceFee: (json['serviceFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      isEscrow: json['isEscrow'] ?? false,
      escrowReleaseDate: json['escrowReleaseDate'] != null
          ? DateTime.parse(json['escrowReleaseDate'])
          : null,
      escrowStatus: json['escrowStatus'] ?? 'pending',
      escrowHeldAt: json['escrowHeldAt'] != null
          ? DateTime.parse(json['escrowHeldAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'amount': amount,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt?.toIso8601String(),
      'isEscrow': isEscrow,
      'escrowReleaseDate': escrowReleaseDate?.toIso8601String(),
      'escrowStatus': escrowStatus,
      'escrowHeldAt': escrowHeldAt?.toIso8601String(),
    };
  }
}