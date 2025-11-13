import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/parcel_entity.dart';

class SenderDetailsModel {
  final String userId;
  final String name;
  final String phoneNumber;
  final String address;
  final String? email;

  const SenderDetailsModel({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.email,
  });

  factory SenderDetailsModel.fromJson(Map<String, dynamic> json) {
    return SenderDetailsModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'email': email,
    };
  }

  SenderDetails toEntity() {
    return SenderDetails(
      userId: userId,
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      email: email,
    );
  }

  factory SenderDetailsModel.fromEntity(SenderDetails entity) {
    return SenderDetailsModel(
      userId: entity.userId,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      email: entity.email,
    );
  }
}

class ReceiverDetailsModel {
  final String name;
  final String phoneNumber;
  final String address;
  final String? email;

  const ReceiverDetailsModel({
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.email,
  });

  factory ReceiverDetailsModel.fromJson(Map<String, dynamic> json) {
    return ReceiverDetailsModel(
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'email': email,
    };
  }

  ReceiverDetails toEntity() {
    return ReceiverDetails(
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      email: email,
    );
  }

  factory ReceiverDetailsModel.fromEntity(ReceiverDetails entity) {
    return ReceiverDetailsModel(
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      email: entity.email,
    );
  }
}

class RouteInformationModel {
  final String origin;
  final String destination;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? estimatedDeliveryDate;
  final String? actualDeliveryDate;

  const RouteInformationModel({
    required this.origin,
    required this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
  });

  factory RouteInformationModel.fromJson(Map<String, dynamic> json) {
    return RouteInformationModel(
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      originLat: json['originLat'] as double?,
      originLng: json['originLng'] as double?,
      destinationLat: json['destinationLat'] as double?,
      destinationLng: json['destinationLng'] as double?,
      estimatedDeliveryDate: json['estimatedDeliveryDate'] as String?,
      actualDeliveryDate: json['actualDeliveryDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'originLat': originLat,
      'originLng': originLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'estimatedDeliveryDate': estimatedDeliveryDate,
      'actualDeliveryDate': actualDeliveryDate,
    };
  }

  RouteInformation toEntity() {
    return RouteInformation(
      origin: origin,
      destination: destination,
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      estimatedDeliveryDate: estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate,
    );
  }

  factory RouteInformationModel.fromEntity(RouteInformation entity) {
    return RouteInformationModel(
      origin: entity.origin,
      destination: entity.destination,
      originLat: entity.originLat,
      originLng: entity.originLng,
      destinationLat: entity.destinationLat,
      destinationLng: entity.destinationLng,
      estimatedDeliveryDate: entity.estimatedDeliveryDate,
      actualDeliveryDate: entity.actualDeliveryDate,
    );
  }
}

class ParcelModel {
  final String id;
  final SenderDetailsModel sender;
  final ReceiverDetailsModel receiver;
  final RouteInformationModel route;
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
  final String? escrowId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ParcelModel({
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
    this.escrowId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory ParcelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParcelModel(
      id: doc.id,
      sender: SenderDetailsModel.fromJson(
          data['sender'] as Map<String, dynamic>? ?? {}),
      receiver: ReceiverDetailsModel.fromJson(
          data['receiver'] as Map<String, dynamic>? ?? {}),
      route: RouteInformationModel.fromJson(
          data['route'] as Map<String, dynamic>? ?? {}),
      status: ParcelStatus.fromString(data['status'] as String? ?? 'created'),
      travelerId: data['travelerId'] as String?,
      travelerName: data['travelerName'] as String?,
      weight: data['weight'] as double?,
      dimensions: data['dimensions'] as String?,
      category: data['category'] as String?,
      description: data['description'] as String?,
      price: data['price'] as double?,
      currency: data['currency'] as String? ?? 'USD',
      imageUrl: data['imageUrl'] as String?,
      escrowId: data['escrowId'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  factory ParcelModel.fromEntity(ParcelEntity entity) {
    return ParcelModel(
      id: entity.id,
      sender: SenderDetailsModel.fromEntity(entity.sender),
      receiver: ReceiverDetailsModel.fromEntity(entity.receiver),
      route: RouteInformationModel.fromEntity(entity.route),
      status: entity.status,
      travelerId: entity.travelerId,
      travelerName: entity.travelerName,
      weight: entity.weight,
      dimensions: entity.dimensions,
      category: entity.category,
      description: entity.description,
      price: entity.price,
      currency: entity.currency,
      imageUrl: entity.imageUrl,
      escrowId: entity.escrowId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'route': route.toJson(),
      'status': status.toJson(),
      'travelerId': travelerId,
      'travelerName': travelerName,
      'weight': weight,
      'dimensions': dimensions,
      'category': category,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'escrowId': escrowId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  ParcelEntity toEntity() {
    return ParcelEntity(
      id: id,
      sender: sender.toEntity(),
      receiver: receiver.toEntity(),
      route: route.toEntity(),
      status: status,
      travelerId: travelerId,
      travelerName: travelerName,
      weight: weight,
      dimensions: dimensions,
      category: category,
      description: description,
      price: price,
      currency: currency,
      imageUrl: imageUrl,
      escrowId: escrowId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  ParcelModel copyWith({
    String? id,
    SenderDetailsModel? sender,
    ReceiverDetailsModel? receiver,
    RouteInformationModel? route,
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
    String? escrowId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ParcelModel(
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
      escrowId: escrowId ?? this.escrowId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
