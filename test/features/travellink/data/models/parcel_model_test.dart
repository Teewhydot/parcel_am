import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parcel_am/features/travellink/data/models/parcel_model.dart';
import 'package:parcel_am/features/travellink/domain/entities/parcel_entity.dart';

void main() {
  group('ParcelModel', () {
    test('should convert from entity correctly', () {
      final entity = ParcelEntity(
        id: 'test-id',
        senderId: 'sender-id',
        title: 'Test Parcel',
        description: 'Test Description',
        type: ParcelType.document,
        weight: 2.5,
        dimensions: {'length': '10', 'width': '5', 'height': '3'},
        fromLocation: 'New York',
        toLocation: 'Los Angeles',
        requestedDeliveryDate: DateTime(2024, 12, 31),
        offeredAmount: 50.0,
        currency: 'USD',
        status: ParcelStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      final model = ParcelModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.senderId, entity.senderId);
      expect(model.title, entity.title);
      expect(model.type, entity.type);
      expect(model.weight, entity.weight);
      expect(model.status, entity.status);
    });

    test('should convert to entity correctly', () {
      final model = ParcelModel(
        id: 'test-id',
        senderId: 'sender-id',
        title: 'Test Parcel',
        description: 'Test Description',
        type: ParcelType.electronics,
        weight: 3.0,
        dimensions: {'length': '15', 'width': '10', 'height': '5'},
        fromLocation: 'Chicago',
        toLocation: 'Miami',
        requestedDeliveryDate: DateTime(2024, 11, 30),
        offeredAmount: 75.0,
        currency: 'USD',
        status: ParcelStatus.accepted,
        createdAt: DateTime(2024, 1, 1),
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.senderId, model.senderId);
      expect(entity.title, model.title);
      expect(entity.type, model.type);
      expect(entity.weight, model.weight);
      expect(entity.status, model.status);
    });
  });
}
