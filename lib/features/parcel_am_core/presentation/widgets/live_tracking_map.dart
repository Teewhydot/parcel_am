import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../bloc/tracking/tracking_state.dart';

/// Interactive map widget for live parcel tracking
class LiveTrackingMap extends StatefulWidget {
  final TrackingData trackingData;
  final double height;

  const LiveTrackingMap({
    super.key,
    required this.trackingData,
    this.height = 250,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  late final MapController _mapController;
  bool _hasAnimatedToCarrier = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate to carrier location when it first becomes available
    if (!_hasAnimatedToCarrier &&
        widget.trackingData.carrierLocation != null &&
        oldWidget.trackingData.carrierLocation == null) {
      _hasAnimatedToCarrier = true;
      _fitBounds();
    }
  }

  void _fitBounds() {
    final points = [
      widget.trackingData.origin,
      widget.trackingData.destination,
      if (widget.trackingData.carrierLocation != null)
        widget.trackingData.carrierLocation!,
    ];

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: AppSpacing.paddingXL,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: AppRadius.md,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _getInitialCenter(),
                initialZoom: 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.parcelam.app',
                ),
                // Markers layer
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
                // Polyline from origin to destination
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        widget.trackingData.origin,
                        widget.trackingData.destination,
                      ],
                      strokeWidth: 3,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
              ],
            ),
            // Live indicator badge
            if (widget.trackingData.isLive)
              Positioned(
                top: 12,
                left: 12,
                child: _buildLiveBadge(),
              ),
            // Fit bounds button
            Positioned(
              top: 12,
              right: 12,
              child: _buildFitBoundsButton(),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _getInitialCenter() {
    // If we have carrier location, center on it
    if (widget.trackingData.carrierLocation != null) {
      return widget.trackingData.carrierLocation!;
    }
    // Otherwise, center between origin and destination
    return LatLng(
      (widget.trackingData.origin.latitude + widget.trackingData.destination.latitude) / 2,
      (widget.trackingData.origin.longitude + widget.trackingData.destination.longitude) / 2,
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Origin marker (green)
    markers.add(
      Marker(
        point: widget.trackingData.origin,
        width: 40,
        height: 40,
        child: _buildLocationMarker(
          icon: Icons.circle,
          color: AppColors.success,
          label: 'From',
        ),
      ),
    );

    // Destination marker (red)
    markers.add(
      Marker(
        point: widget.trackingData.destination,
        width: 40,
        height: 40,
        child: _buildLocationMarker(
          icon: Icons.location_on,
          color: AppColors.error,
          label: 'To',
        ),
      ),
    );

    // Carrier marker (if available)
    if (widget.trackingData.carrierLocation != null) {
      markers.add(
        Marker(
          point: widget.trackingData.carrierLocation!,
          width: 48,
          height: 48,
          child: _buildCarrierMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildLocationMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: AppSpacing.paddingXS,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCarrierMarker() {
    final vehicleIcon = _getVehicleIcon(widget.trackingData.vehicleType);

    return Transform.rotate(
      angle: widget.trackingData.heading * (3.14159 / 180), // Convert degrees to radians
      child: Container(
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          vehicleIcon,
          color: AppColors.white,
          size: 20,
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    return switch (vehicleType.toLowerCase()) {
      'plane' => Icons.flight,
      'car' => Icons.directions_car,
      'bike' => Icons.two_wheeler,
      'truck' => Icons.local_shipping,
      _ => Icons.directions_car,
    };
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: AppRadius.md,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.xs),
          AppText.labelSmall(
            'Live',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildFitBoundsButton() {
    return GestureDetector(
      onTap: _fitBounds,
      child: Container(
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.fit_screen,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
