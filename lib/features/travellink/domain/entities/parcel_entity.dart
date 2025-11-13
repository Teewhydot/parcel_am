import 'package:equatable/equatable.dart';

enum ParcelStatus {
  created,
  paid,
  inTransit,
  delivered,
  cancelled,
  disputed;

  String get displayName {
    switch (this) {
      case ParcelStatus.created:
        return 'Created';
      case ParcelStatus.paid:
        return 'Paid';
      case ParcelStatus.inTransit:
        return 'In Transit';
      case ParcelStatus.delivered:
        return 'Delivered';
      case ParcelStatus.cancelled:
        return 'Cancelled';
      case ParcelStatus.disputed:
        return 'Disputed';
    }
  }

  String toJson() {
    switch (this) {
      case ParcelStatus.created:
        return 'created';
      case ParcelStatus.paid:
        return 'paid';
      case ParcelStatus.inTransit:
        return 'in_transit';
      case ParcelStatus.delivered:
        return 'delivered';
      case ParcelStatus.cancelled:
        return 'cancelled';
      case ParcelStatus.disputed:
        return 'disputed';
    }
  }

  static ParcelStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'created':
        return ParcelStatus.created;
      case 'paid':
        return ParcelStatus.paid;
      case 'in_transit':
      case 'intransit':
        return ParcelStatus.inTransit;
      case 'delivered':
        return ParcelStatus.delivered;
      case 'cancelled':
        return ParcelStatus.cancelled;
      case 'disputed':
        return ParcelStatus.disputed;
      default:
        return ParcelStatus.created;
    }
  }

  bool get isActive => this == ParcelStatus.paid || this == ParcelStatus.inTransit;
  bool get isCompleted => this == ParcelStatus.delivered;
  bool get isCancelled => this == ParcelStatus.cancelled;
  bool get isDisputed => this == ParcelStatus.disputed;
}

class SenderDetails extends Equatable {
  final String userId;
  final String name;
  final String phoneNumber;
  final String address;
  final String? email;

  const SenderDetails({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.email,
  });

  SenderDetails copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? address,
    String? email,
  }) {
    return SenderDetails(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [userId, name, phoneNumber, address, email];
}

class ReceiverDetails extends Equatable {
  final String name;
  final String phoneNumber;
  final String address;
  final String? email;

  const ReceiverDetails({
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.email,
  });

  ReceiverDetails copyWith({
    String? name,
    String? phoneNumber,
    String? address,
    String? email,
  }) {
    return ReceiverDetails(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [name, phoneNumber, address, email];
}

class RouteInformation extends Equatable {
  final String origin;
  final String destination;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? estimatedDeliveryDate;
  final String? actualDeliveryDate;

  const RouteInformation({
    required this.origin,
    required this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
  });

  RouteInformation copyWith({
    String? origin,
    String? destination,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    String? estimatedDeliveryDate,
    String? actualDeliveryDate,
  }) {
    return RouteInformation(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
    );
  }

  @override
  List<Object?> get props => [
        origin,
        destination,
        originLat,
        originLng,
        destinationLat,
        destinationLng,
        estimatedDeliveryDate,
        actualDeliveryDate,
      ];
}

class ParcelEntity extends Equatable {
  final String id;
  final SenderDetails sender;
  final ReceiverDetails receiver;
  final RouteInformation route;
  final ParcelStatus status;
  final String? travelerId;
  final String? travelerName;
  final double? weight;
  final String? dimensions;
  final String? category;
  final String? description;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ParcelEntity({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.route,
    required this.status,
    this.travelerId,
    this.travelerName,
    this.weight,
    this.dimensions,
    this.category,
    this.description,
    this.price,
    this.currency,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  ParcelEntity copyWith({
    String? id,
    SenderDetails? sender,
    ReceiverDetails? receiver,
    RouteInformation? route,
    ParcelStatus? status,
    String? travelerId,
    String? travelerName,
    double? weight,
    String? dimensions,
    String? category,
    String? description,
    double? price,
    String? currency,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ParcelEntity(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      route: route ?? this.route,
      status: status ?? this.status,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        receiver,
        route,
        status,
        travelerId,
        travelerName,
        weight,
        dimensions,
        category,
        description,
        price,
        currency,
        imageUrl,
        createdAt,
        updatedAt,
        metadata,
      ];
}
