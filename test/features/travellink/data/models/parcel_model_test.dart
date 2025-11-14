import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/travellink/domain/entities/parcel_entity.dart';

void main() {
  group('ParcelModel', () {
    test('should create a valid ParcelEntity', () {
      final now = DateTime.now();
      final entity = ParcelEntity(
        id: 'test-id',
        sender: const SenderDetails(
          userId: 'sender-id',
          name: 'John Doe',
          phoneNumber: '+1234567890',
          address: '123 Main St, New York',
        ),
        receiver: const ReceiverDetails(
          name: 'Jane Smith',
          phoneNumber: '+0987654321',
          address: '456 Oak Ave, Los Angeles',
        ),
        route: const RouteInformation(
          origin: 'New York',
          destination: 'Los Angeles',
          estimatedDeliveryDate: '2024-12-31',
        ),
        description: 'Test Description',
        weight: 2.5,
        category: 'documents',
        price: 50.0,
        currency: 'USD',
        status: ParcelStatus.created,
        createdAt: now,
      );

      expect(entity.id, 'test-id');
      expect(entity.sender.userId, 'sender-id');
      expect(entity.receiver.name, 'Jane Smith');
      expect(entity.route.origin, 'New York');
      expect(entity.route.destination, 'Los Angeles');
      expect(entity.weight, 2.5);
      expect(entity.status, ParcelStatus.created);
    });

    test('should handle nullable fields correctly', () {
      final now = DateTime.now();
      final entity = ParcelEntity(
        id: 'test-id',
        sender: const SenderDetails(
          userId: 'sender-id',
          name: 'John Doe',
          phoneNumber: '+1234567890',
          address: '123 Main St',
        ),
        receiver: const ReceiverDetails(
          name: 'Jane Smith',
          phoneNumber: '+0987654321',
          address: '456 Oak Ave',
        ),
        route: const RouteInformation(
          origin: 'Chicago',
          destination: 'Miami',
        ),
        status: ParcelStatus.paid,
        createdAt: now,
      );

      expect(entity.description, null);
      expect(entity.weight, null);
      expect(entity.price, null);
    });
  });
}
