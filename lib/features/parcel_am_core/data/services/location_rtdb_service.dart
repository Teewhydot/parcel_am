import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Data model for carrier location updates
class CarrierLocation {
  final String carrierId;
  final LatLng position;
  final double heading;
  final double speed;
  final String? address;
  final DateTime lastUpdated;

  CarrierLocation({
    required this.carrierId,
    required this.position,
    required this.heading,
    required this.speed,
    this.address,
    required this.lastUpdated,
  });

  factory CarrierLocation.fromMap(Map<String, dynamic> map) {
    final latitude = (map['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (map['longitude'] as num?)?.toDouble() ?? 0.0;
    final timestamp = map['lastUpdated'];

    DateTime lastUpdated;
    if (timestamp is int) {
      lastUpdated = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      lastUpdated = DateTime.now();
    }

    return CarrierLocation(
      carrierId: map['carrierId'] as String? ?? '',
      position: LatLng(latitude, longitude),
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String?,
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carrierId': carrierId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': heading,
      'speed': speed,
      'address': address,
      'lastUpdated': ServerValue.timestamp,
    };
  }
}

/// Service for real-time carrier location tracking using Firebase Realtime Database.
/// RTDB provides lower latency (~50ms) compared to Firestore (~200-500ms).
class LocationRtdbService {
  static final LocationRtdbService _instance = LocationRtdbService._internal();
  factory LocationRtdbService() => _instance;
  LocationRtdbService._internal();

  /// Lazily initialized database instance
  FirebaseDatabase? _database;

  /// Get the database instance, initializing if needed
  FirebaseDatabase get database {
    _database ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://parcel-am-default-rtdb.europe-west1.firebasedatabase.app',
    );
    return _database!;
  }

  /// Reference to parcel locations in RTDB
  /// Structure: /parcel_locations/{parcelId} = { carrierId, latitude, longitude, ... }
  DatabaseReference _locationRef(String parcelId) {
    return database.ref('parcel_locations/$parcelId');
  }

  /// Update the carrier's current location for a parcel
  /// Called by the carrier app when location changes
  Future<void> updateCarrierLocation({
    required String parcelId,
    required String carrierId,
    required Position position,
    String? address,
  }) async {
    final locationData = {
      'carrierId': carrierId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': position.heading,
      'speed': position.speed,
      'address': address,
      'lastUpdated': ServerValue.timestamp,
    };

    await _locationRef(parcelId).set(locationData);
  }

  /// Watch the carrier's location for a parcel in real-time
  /// Returns a stream of CarrierLocation updates
  Stream<CarrierLocation?> watchCarrierLocation(String parcelId) {
    return _locationRef(parcelId).onValue.map((event) {
      if (event.snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return CarrierLocation.fromMap(data);
    });
  }

  /// Get the carrier's current location (one-time fetch)
  Future<CarrierLocation?> getCarrierLocation(String parcelId) async {
    final snapshot = await _locationRef(parcelId).get();

    if (snapshot.value == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return CarrierLocation.fromMap(data);
  }

  /// Stop location updates for a parcel (called when delivery is completed)
  Future<void> stopLocationUpdates(String parcelId) async {
    await _locationRef(parcelId).remove();
  }

  /// Check if location tracking is active for a parcel
  Future<bool> isTrackingActive(String parcelId) async {
    final snapshot = await _locationRef(parcelId).get();
    return snapshot.exists;
  }
}
