import 'package:equatable/equatable.dart';
import '../../../domain/entities/parcel_entity.dart';

abstract class ParcelEvent extends Equatable {
  const ParcelEvent();

  @override
  List<Object?> get props => [];
}

class ParcelCreateRequested extends ParcelEvent {
  final ParcelEntity parcel;

  const ParcelCreateRequested(this.parcel);

  @override
  List<Object?> get props => [parcel];
}

class ParcelUpdateStatusRequested extends ParcelEvent {
  final String parcelId;
  final ParcelStatus status;

  const ParcelUpdateStatusRequested({
    required this.parcelId,
    required this.status,
  });

  @override
  List<Object?> get props => [parcelId, status];
}

class ParcelWatchRequested extends ParcelEvent {
  final String parcelId;

  const ParcelWatchRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class ParcelWatchUserParcelsRequested extends ParcelEvent {
  final String userId;

  const ParcelWatchUserParcelsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ParcelStatusUpdated extends ParcelEvent {
  final ParcelEntity parcel;

  const ParcelStatusUpdated(this.parcel);

  @override
  List<Object?> get props => [parcel];
}

class ParcelListUpdated extends ParcelEvent {
  final List<ParcelEntity> parcels;

  const ParcelListUpdated(this.parcels);

  @override
  List<Object?> get props => [parcels];
}

class ParcelLoadRequested extends ParcelEvent {
  final String parcelId;

  const ParcelLoadRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class ParcelLoadUserParcels extends ParcelEvent {
  final String userId;

  const ParcelLoadUserParcels(this.userId);

  @override
  List<Object?> get props => [userId];
}
