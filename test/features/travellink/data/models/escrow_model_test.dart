import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parcel_am/features/travellink/data/models/escrow_model.dart';
import 'package:parcel_am/features/travellink/domain/entities/escrow_entity.dart';

void main() {
  group('EscrowModel', () {
    test('should convert from entity correctly', () {
      final entity = EscrowEntity(
        id: 'test-id',
        parcelId: 'parcel-id',
        senderId: 'sender-id',
        travelerId: 'traveler-id',
        amount: 100.0,
        currency: 'USD',
        status: EscrowStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      final model = EscrowModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.parcelId, entity.parcelId);
      expect(model.senderId, entity.senderId);
      expect(model.travelerId, entity.travelerId);
      expect(model.amount, entity.amount);
      expect(model.currency, entity.currency);
      expect(model.status, entity.status);
    });

    test('should convert to entity correctly', () {
      final model = EscrowModel(
        id: 'test-id',
        parcelId: 'parcel-id',
        senderId: 'sender-id',
        travelerId: 'traveler-id',
        amount: 100.0,
        currency: 'USD',
        status: EscrowStatus.held,
        createdAt: DateTime(2024, 1, 1),
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.parcelId, model.parcelId);
      expect(entity.senderId, model.senderId);
      expect(entity.travelerId, model.travelerId);
      expect(entity.amount, model.amount);
      expect(entity.currency, model.currency);
      expect(entity.status, model.status);
    });
  });
}
