import 'package:latlong2/latlong.dart';

/// Data class for tracking information
class TrackingData {
  final LatLng? carrierLocation;
  final double heading;
  final double speed;
  final String? address;
  final DateTime? lastUpdated;
  final double? distanceToDestination;
  final LatLng origin;
  final LatLng destination;
  final String vehicleType;
  final bool isLive;

  const TrackingData({
    this.carrierLocation,
    this.heading = 0.0,
    this.speed = 0.0,
    this.address,
    this.lastUpdated,
    this.distanceToDestination,
    required this.origin,
    required this.destination,
    this.vehicleType = 'car',
    this.isLive = false,
  });

  TrackingData copyWith({
    LatLng? carrierLocation,
    double? heading,
    double? speed,
    String? address,
    DateTime? lastUpdated,
    double? distanceToDestination,
    LatLng? origin,
    LatLng? destination,
    String? vehicleType,
    bool? isLive,
  }) {
    return TrackingData(
      carrierLocation: carrierLocation ?? this.carrierLocation,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      address: address ?? this.address,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      distanceToDestination: distanceToDestination ?? this.distanceToDestination,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      vehicleType: vehicleType ?? this.vehicleType,
      isLive: isLive ?? this.isLive,
    );
  }

  /// Format speed in km/h
  String get formattedSpeed {
    if (speed <= 0) return 'Stationary';
    final kmh = speed * 3.6; // Convert m/s to km/h
    return '${kmh.toStringAsFixed(0)} km/h';
  }

  /// Format distance in km or m
  String get formattedDistance {
    if (distanceToDestination == null) return 'Calculating...';
    if (distanceToDestination! < 1000) {
      return '${distanceToDestination!.toStringAsFixed(0)} m';
    }
    return '${(distanceToDestination! / 1000).toStringAsFixed(1)} km';
  }

  /// Get time since last update
  String get lastUpdateText {
    if (lastUpdated == null) return 'No updates yet';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
