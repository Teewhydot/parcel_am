import '../../../domain/entities/parcel_entity.dart';

class ParcelData {
  final ParcelEntity? currentParcel;
  final List<ParcelEntity> userParcels;

  const ParcelData({
    this.currentParcel,
    this.userParcels = const [],
  });

  ParcelData copyWith({
    ParcelEntity? currentParcel,
    List<ParcelEntity>? userParcels,
  }) {
    return ParcelData(
      currentParcel: currentParcel ?? this.currentParcel,
      userParcels: userParcels ?? this.userParcels,
    );
  }
}
