import '../../../domain/entities/parcel_entity.dart';

/// Holds the data for the parcel feature including various parcel lists.
///
/// Contains lists for:
/// - currentParcel: The currently selected parcel for detail viewing
/// - userParcels: Parcels created by the current user (as sender)
/// - availableParcels: Parcels available for couriers to accept
/// - acceptedParcels: Parcels accepted by the current user (as traveler/courier)
class ParcelData {
  final ParcelEntity? currentParcel;
  final List<ParcelEntity> userParcels;
  final List<ParcelEntity> availableParcels;

  /// List of parcels where the current user is the traveler/courier.
  /// These are deliveries the user has accepted and is responsible for.
  final List<ParcelEntity> acceptedParcels;

  const ParcelData({
    this.currentParcel,
    this.userParcels = const [],
    this.availableParcels = const [],
    this.acceptedParcels = const [],
  });

  /// Creates a copy of this ParcelData with the given fields replaced with new values.
  ParcelData copyWith({
    ParcelEntity? currentParcel,
    List<ParcelEntity>? userParcels,
    List<ParcelEntity>? availableParcels,
    List<ParcelEntity>? acceptedParcels,
  }) {
    return ParcelData(
      currentParcel: currentParcel ?? this.currentParcel,
      userParcels: userParcels ?? this.userParcels,
      availableParcels: availableParcels ?? this.availableParcels,
      acceptedParcels: acceptedParcels ?? this.acceptedParcels,
    );
  }

  /// Returns a filtered list of accepted parcels with active status.
  ///
  /// Active statuses include: paid, pickedUp, inTransit, arrived
  /// These represent in-progress deliveries that require courier action.
  List<ParcelEntity> get activeParcels {
    return acceptedParcels.where((parcel) => parcel.status.isActive).toList();
  }

  /// Returns a filtered list of accepted parcels with completed status.
  ///
  /// Completed status: delivered
  /// These represent successfully completed deliveries.
  List<ParcelEntity> get completedParcels {
    return acceptedParcels.where((parcel) => parcel.status.isCompleted).toList();
  }
}
