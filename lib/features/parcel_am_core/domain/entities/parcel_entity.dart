import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ParcelStatus {
  created,
  paid,
  pickedUp,
  inTransit,
  arrived,
  awaitingConfirmation,
  delivered,
  cancelled,
  disputed;

  String get displayName {
    switch (this) {
      case ParcelStatus.created:
        return 'Created';
      case ParcelStatus.paid:
        return 'Paid';
      case ParcelStatus.pickedUp:
        return 'Picked Up';
      case ParcelStatus.inTransit:
        return 'In Transit';
      case ParcelStatus.arrived:
        return 'Arrived';
      case ParcelStatus.awaitingConfirmation:
        return 'Awaiting Confirmation';
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
      case ParcelStatus.pickedUp:
        return 'picked_up';
      case ParcelStatus.inTransit:
        return 'in_transit';
      case ParcelStatus.arrived:
        return 'arrived';
      case ParcelStatus.awaitingConfirmation:
        return 'awaiting_confirmation';
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
      case 'picked_up':
      case 'pickedup':
        return ParcelStatus.pickedUp;
      case 'in_transit':
      case 'intransit':
        return ParcelStatus.inTransit;
      case 'arrived':
        return ParcelStatus.arrived;
      case 'awaiting_confirmation':
      case 'awaitingconfirmation':
        return ParcelStatus.awaitingConfirmation;
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

  /// Returns true if this status is considered active (in-progress delivery).
  /// Active statuses: paid, pickedUp, inTransit, arrived, awaitingConfirmation
  bool get isActive =>
      this == ParcelStatus.paid ||
      this == ParcelStatus.pickedUp ||
      this == ParcelStatus.inTransit ||
      this == ParcelStatus.arrived ||
      this == ParcelStatus.awaitingConfirmation;

  bool get isCompleted => this == ParcelStatus.delivered;
  bool get isCancelled => this == ParcelStatus.cancelled;
  bool get isDisputed => this == ParcelStatus.disputed;

  /// Returns true if the status can progress to the next valid status by the courier.
  /// Returns false for terminal statuses (delivered, cancelled, disputed)
  /// and for awaitingConfirmation (only sender can confirm).
  bool get canProgressToNextStatus {
    switch (this) {
      case ParcelStatus.paid:
      case ParcelStatus.pickedUp:
      case ParcelStatus.inTransit:
      case ParcelStatus.arrived:
        return true;
      case ParcelStatus.created:
      case ParcelStatus.awaitingConfirmation: // Only sender can confirm
      case ParcelStatus.delivered:
      case ParcelStatus.cancelled:
      case ParcelStatus.disputed:
        return false;
    }
  }

  /// Returns the next valid status in the delivery progression flow.
  /// Returns null if there is no valid next status (terminal state).
  ///
  /// Status progression flow: paid -> pickedUp -> inTransit -> arrived -> awaitingConfirmation -> delivered
  ParcelStatus? get nextDeliveryStatus {
    switch (this) {
      case ParcelStatus.paid:
        return ParcelStatus.pickedUp;
      case ParcelStatus.pickedUp:
        return ParcelStatus.inTransit;
      case ParcelStatus.inTransit:
        return ParcelStatus.arrived;
      case ParcelStatus.arrived:
        return ParcelStatus.awaitingConfirmation;
      case ParcelStatus.awaitingConfirmation:
        return ParcelStatus.delivered;
      case ParcelStatus.created:
      case ParcelStatus.delivered:
      case ParcelStatus.cancelled:
      case ParcelStatus.disputed:
        return null;
    }
  }

  /// Returns the color associated with this status for visual indicators.
  /// Used for status badges, chips, and other UI elements.
  Color get statusColor {
    switch (this) {
      case ParcelStatus.created:
        return AppColors.onSurfaceVariant;
      case ParcelStatus.paid:
        return AppColors.processing;
      case ParcelStatus.pickedUp:
        return AppColors.pending;
      case ParcelStatus.inTransit:
        return AppColors.reversed;
      case ParcelStatus.arrived:
        return AppColors.secondary;
      case ParcelStatus.awaitingConfirmation:
        return AppColors.warning;
      case ParcelStatus.delivered:
        return AppColors.success;
      case ParcelStatus.cancelled:
        return AppColors.error;
      case ParcelStatus.disputed:
        return AppColors.warning;
    }
  }

  /// Returns true if this parcel is awaiting sender confirmation.
  bool get isAwaitingConfirmation => this == ParcelStatus.awaitingConfirmation;
}

enum ParcelType {
  document,
  electronics,
  clothing,
  food,
  medication,
  other,
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

/// Represents a parcel delivery request in the system.
///
/// Metadata map structure for delivery tracking:
/// - deliveryStatusHistory: Map of status to ISO timestamp
///   Example: {"paid": "2025-11-25T10:30:00Z", "picked_up": "2025-11-25T12:00:00Z"}
/// - courierNotes: String (optional delivery notes from courier)
/// - lastStatusUpdate: String (ISO timestamp of the most recent status change)
///
/// The metadata field is designed for backward compatibility and flexible extension
/// without requiring schema migrations.
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
  final String? escrowId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Timestamp of the most recent status update.
  /// Used for sorting deliveries by recent activity.
  final DateTime? lastStatusUpdate;

  /// Optional notes from the courier about the delivery.
  /// Can include pickup/delivery instructions, issues encountered, etc.
  final String? courierNotes;

  /// Flexible metadata field for delivery tracking and future extensions.
  /// See class documentation for structure details.
  final Map<String, dynamic>? metadata;

  /// Timestamp when status became awaitingConfirmation.
  final DateTime? awaitingConfirmationAt;

  /// Timestamp when sender confirmed delivery.
  final DateTime? confirmedAt;

  /// User ID who confirmed delivery (sender or 'system_auto_release').
  final String? confirmedBy;

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
    this.escrowId,
    required this.createdAt,
    this.updatedAt,
    this.lastStatusUpdate,
    this.courierNotes,
    this.metadata,
    this.awaitingConfirmationAt,
    this.confirmedAt,
    this.confirmedBy,
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
    String? escrowId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastStatusUpdate,
    String? courierNotes,
    Map<String, dynamic>? metadata,
    DateTime? awaitingConfirmationAt,
    DateTime? confirmedAt,
    String? confirmedBy,
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
      escrowId: escrowId ?? this.escrowId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
      courierNotes: courierNotes ?? this.courierNotes,
      metadata: metadata ?? this.metadata,
      awaitingConfirmationAt: awaitingConfirmationAt ?? this.awaitingConfirmationAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
    );
  }

  /// Returns the delivery status history as a map of status to timestamp.
  /// Parses the metadata field to extract status change timestamps.
  ///
  /// Returns an empty map if metadata is null or doesn't contain history.
  Map<String, DateTime> get deliveryStatusHistory {
    if (metadata == null || metadata!['deliveryStatusHistory'] == null) {
      return {};
    }

    final historyMap = metadata!['deliveryStatusHistory'] as Map<String, dynamic>;
    final result = <String, DateTime>{};

    historyMap.forEach((key, value) {
      if (value is String) {
        try {
          result[key] = DateTime.parse(value);
        } catch (e) {
          // Skip invalid timestamps
        }
      }
    });

    return result;
  }

  /// Returns the timestamp when a specific status was reached.
  /// Returns null if the status was never reached or timestamp is unavailable.
  ///
  /// Example:
  /// ```dart
  /// final pickedUpTime = parcel.getStatusTimestamp(ParcelStatus.pickedUp);
  /// ```
  DateTime? getStatusTimestamp(ParcelStatus status) {
    final history = deliveryStatusHistory;
    final statusKey = status.toJson();
    return history[statusKey];
  }

  /// Returns an ordered list of statuses that have been completed.
  /// Ordered by the standard progression flow, not by timestamp.
  ///
  /// Example: [ParcelStatus.paid, ParcelStatus.pickedUp, ParcelStatus.inTransit]
  List<ParcelStatus> get statusHistory {
    final history = deliveryStatusHistory;
    final allStatuses = [
      ParcelStatus.paid,
      ParcelStatus.pickedUp,
      ParcelStatus.inTransit,
      ParcelStatus.arrived,
      ParcelStatus.awaitingConfirmation,
      ParcelStatus.delivered,
    ];

    return allStatuses.where((status) {
      return history.containsKey(status.toJson());
    }).toList();
  }

  /// Checks if the current user is the traveler/courier for this delivery.
  /// Returns true if the provided userId matches the travelerId.
  ///
  /// Note: Requires passing the current user ID as a parameter since
  /// the entity should not depend on global auth state.
  bool isMyDelivery(String currentUserId) {
    return travelerId != null && travelerId == currentUserId;
  }

  /// Returns true if the delivery is urgent (within 48 hours).
  /// Based on the estimated delivery date in route information.
  bool get hasUrgentDelivery {
    if (route.estimatedDeliveryDate == null) {
      return false;
    }

    try {
      final estimatedDate = DateTime.parse(route.estimatedDeliveryDate!);
      final now = DateTime.now();
      final difference = estimatedDate.difference(now);

      return difference.inHours <= 48 && difference.inHours >= 0;
    } catch (e) {
      return false;
    }
  }

  /// Calculates the time remaining until estimated delivery.
  /// Returns null if no estimated delivery date is available.
  /// Returns negative duration if delivery date has passed.
  Duration? get timeUntilDelivery {
    if (route.estimatedDeliveryDate == null) {
      return null;
    }

    try {
      final estimatedDate = DateTime.parse(route.estimatedDeliveryDate!);
      final now = DateTime.now();
      return estimatedDate.difference(now);
    } catch (e) {
      return null;
    }
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
        escrowId,
        createdAt,
        updatedAt,
        lastStatusUpdate,
        courierNotes,
        metadata,
        awaitingConfirmationAt,
        confirmedAt,
        confirmedBy,
      ];
}
