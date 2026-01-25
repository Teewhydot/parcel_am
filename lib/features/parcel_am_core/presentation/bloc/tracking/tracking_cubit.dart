import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../data/services/location_rtdb_service.dart';
import '../../../domain/entities/package_entity.dart';
import 'tracking_state.dart';

class TrackingCubit extends BaseCubit<BaseState<TrackingData>> {
  final LocationRtdbService _locationService;
  StreamSubscription<CarrierLocation?>? _locationSubscription;
  String? _currentParcelId;

  TrackingCubit({
    LocationRtdbService? locationService,
  })  : _locationService = locationService ?? LocationRtdbService(),
        super(const InitialState<TrackingData>());

  /// Start tracking a parcel's carrier location
  /// Only the sender should be able to call this
  void startTracking({
    required String parcelId,
    required String currentUserId,
    required PackageEntity package,
  }) {
    // Verify sender-only access
    if (package.senderId != currentUserId) {
      emit(const ErrorState<TrackingData>(
        errorMessage: 'Only the sender can track this parcel',
      ));
      return;
    }

    // Stop any existing tracking
    stopTracking();
    _currentParcelId = parcelId;

    // Extract origin and destination coordinates
    final origin = LatLng(
      package.origin.latitude,
      package.origin.longitude,
    );
    final destination = LatLng(
      package.destination.latitude,
      package.destination.longitude,
    );

    // Emit initial tracking data with route info
    final initialData = TrackingData(
      origin: origin,
      destination: destination,
      vehicleType: package.carrier.vehicleType,
      isLive: false,
    );
    emit(LoadedState<TrackingData>(
      data: initialData,
      lastUpdated: DateTime.now(),
    ));

    // Start listening to location updates
    _locationSubscription = _locationService
        .watchCarrierLocation(parcelId)
        .listen(
          (location) => _onLocationUpdate(location, destination, initialData.vehicleType),
          onError: (error) {
            emit(AsyncErrorState<TrackingData>(
              errorMessage: 'Failed to track location: $error',
              data: state.data,
            ));
          },
        );
  }

  void _onLocationUpdate(
    CarrierLocation? location,
    LatLng destination,
    String vehicleType,
  ) {
    final currentData = state.data;
    if (currentData == null) return;

    if (location == null) {
      // No location data yet - carrier hasn't started broadcasting
      emit(LoadedState<TrackingData>(
        data: currentData.copyWith(isLive: false),
        lastUpdated: DateTime.now(),
      ));
      return;
    }

    // Calculate distance to destination
    final distanceToDestination = Geolocator.distanceBetween(
      location.position.latitude,
      location.position.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Update tracking data with new location
    final updatedData = currentData.copyWith(
      carrierLocation: location.position,
      heading: location.heading,
      speed: location.speed,
      address: location.address,
      lastUpdated: location.lastUpdated,
      distanceToDestination: distanceToDestination,
      isLive: true,
    );

    emit(LoadedState<TrackingData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  /// Stop tracking the current parcel
  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentParcelId = null;
  }

  /// Refresh tracking - useful if stream gets disconnected
  void refreshTracking(PackageEntity package, String currentUserId) {
    if (_currentParcelId != null) {
      startTracking(
        parcelId: _currentParcelId!,
        currentUserId: currentUserId,
        package: package,
      );
    }
  }

  /// Check if tracking is currently active
  bool get isTracking => _locationSubscription != null;

  @override
  Future<void> close() {
    stopTracking();
    return super.close();
  }
}
