import '../../../domain/entities/parcel_entity.dart';

class ParcelData {
  final ParcelEntity? currentParcel;
  final List<ParcelEntity> userParcels;
  final List<ParcelEntity> availableParcels;

  const ParcelData({
    this.currentParcel,
    this.userParcels = const [],
    this.availableParcels = const [],
  });

  ParcelData copyWith({
    ParcelEntity? currentParcel,
    List<ParcelEntity>? userParcels,
    List<ParcelEntity>? availableParcels,
  }) {
    return ParcelData(
      currentParcel: currentParcel ?? this.currentParcel,
      userParcels: userParcels ?? this.userParcels,
      availableParcels: availableParcels ?? this.availableParcels,
    );
  }
}
