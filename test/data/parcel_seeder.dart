import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/parcel_entity.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/parcel_model.dart' show ParcelModel, SenderDetailsModel, ReceiverDetailsModel, RouteInformationModel;

class ParcelSeeder {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ParcelSeeder({
    required this.firestore,
    required this.auth,
  });

  Future<List<String>> seedTestParcels() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to seed data');
    }

    final testParcels = _generateTestParcels(currentUser.uid);
    final parcelIds = <String>[];

    for (final parcel in testParcels) {
      try {
        final docRef = firestore.collection('parcels').doc();
        final parcelData = parcel.toJson();
        parcelData['createdAt'] = FieldValue.serverTimestamp();

        await docRef.set(parcelData);
        parcelIds.add(docRef.id);
      } catch (e) {
        print('Error seeding parcel: $e');
      }
    }

    return parcelIds;
  }

  Future<void> clearTestParcels() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to clear data');
    }

    // Delete parcels created by current user with status 'created'
    final querySnapshot = await firestore
        .collection('parcels')
        .where('sender.userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'created')
        .get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  List<ParcelModel> _generateTestParcels(String userId) {
    final now = DateTime.now();

    return [
      // Parcel 1: Electronics - Lagos to Abuja (Urgent)
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'John Doe',
          phoneNumber: '+234 803 123 4567',
          address: '123 Allen Avenue, Ikeja, Lagos',
          email: 'john.doe@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Jane Smith',
          phoneNumber: '+234 806 789 0123',
          address: '45 Constitution Avenue, Central District, Abuja',
          email: 'jane.smith@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Lagos',
          destination: 'Abuja',
          originLat: 6.5244,
          originLng: 3.3792,
          destinationLat: 9.0579,
          destinationLng: 7.4951,
          estimatedDeliveryDate: now.add(const Duration(days: 1)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 2.5,
        dimensions: '40cm x 30cm x 15cm',
        category: 'Electronics',
        description: 'Brand new laptop in original sealed packaging. Handle with extreme care - fragile and valuable.',
        price: 15000,
        currency: 'NGN',
        escrowId: 'ESCROW-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: now,
      ),

      // Parcel 2: Documents - Lagos to Port Harcourt
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Ahmed Ibrahim',
          phoneNumber: '+234 805 234 5678',
          address: '78 Victoria Island, Lagos',
          email: 'ahmed.ibrahim@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Chioma Okafor',
          phoneNumber: '+234 807 890 1234',
          address: '12 Trans Amadi, Port Harcourt',
          email: 'chioma.okafor@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Lagos',
          destination: 'Port Harcourt',
          originLat: 6.5244,
          originLng: 3.3792,
          destinationLat: 4.8156,
          destinationLng: 7.0498,
          estimatedDeliveryDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 0.5,
        dimensions: 'A4 envelope size',
        category: 'Documents',
        description: 'Important legal documents for business meeting. Time-sensitive and confidential.',
        price: 5000,
        currency: 'NGN',
        escrowId: '',
        createdAt: now,
      ),

      // Parcel 3: Fashion - Abuja to Lagos
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Fatima Bello',
          phoneNumber: '+234 808 345 6789',
          address: '34 Wuse 2, Abuja',
          email: 'fatima.bello@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Tunde Williams',
          phoneNumber: '+234 809 901 2345',
          address: '56 Lekki Phase 1, Lagos',
          email: 'tunde.williams@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Abuja',
          destination: 'Lagos',
          originLat: 9.0579,
          originLng: 7.4951,
          destinationLat: 6.5244,
          destinationLng: 3.3792,
          estimatedDeliveryDate: now.add(const Duration(days: 3)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 1.2,
        dimensions: '35cm x 25cm x 8cm',
        category: 'Clothing',
        description: 'Designer outfit for wedding ceremony. Please keep flat and avoid folding.',
        price: 8500,
        currency: 'NGN',
        escrowId: '',
        createdAt: now,
      ),

      // Parcel 4: Food/Medication - Port Harcourt to Lagos
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Dr. Emeka Nwosu',
          phoneNumber: '+234 810 456 7890',
          address: '90 GRA Phase 2, Port Harcourt',
          email: 'emeka.nwosu@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Mrs. Aisha Abdullahi',
          phoneNumber: '+234 811 567 8901',
          address: '23 Maryland, Lagos',
          email: 'aisha.abdullahi@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Port Harcourt',
          destination: 'Lagos',
          originLat: 4.8156,
          originLng: 7.0498,
          destinationLat: 6.5244,
          destinationLng: 3.3792,
          estimatedDeliveryDate: now.add(const Duration(hours: 18)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 0.8,
        dimensions: '20cm x 15cm x 10cm (insulated)',
        category: 'Medication',
        description: 'Temperature-sensitive medication. Must be kept cool. Urgent delivery required.',
        price: 12000,
        currency: 'NGN',
        escrowId: 'ESCROW-${DateTime.now().millisecondsSinceEpoch + 1}',
        createdAt: now,
      ),

      // Parcel 5: Books - Abuja to Port Harcourt
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Prof. Chukwudi Okeke',
          phoneNumber: '+234 812 678 9012',
          address: '15 Garki Area, Abuja',
          email: 'prof.okeke@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Student Union',
          phoneNumber: '+234 813 789 0123',
          address: 'University of Port Harcourt, East-West Road',
          email: 'studentunion@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Abuja',
          destination: 'Port Harcourt',
          originLat: 9.0579,
          originLng: 7.4951,
          destinationLat: 4.8156,
          destinationLng: 7.0498,
          estimatedDeliveryDate: now.add(const Duration(days: 4)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 5.0,
        dimensions: '45cm x 35cm x 20cm',
        category: 'Books',
        description: 'Collection of academic textbooks for university library. Heavy but not fragile.',
        price: 6000,
        currency: 'NGN',
        escrowId: '',
        createdAt: now,
      ),

      // Parcel 6: Electronics - Lagos to Lagos (Same city)
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Tech Store Lagos',
          phoneNumber: '+234 814 890 1234',
          address: 'Computer Village, Ikeja, Lagos',
          email: 'techstore@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Oluwaseun Adeleke',
          phoneNumber: '+234 815 901 2345',
          address: '67 Ikoyi, Lagos',
          email: 'oluwaseun@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Lagos',
          destination: 'Lagos',
          originLat: 6.6018,
          originLng: 3.3515,
          destinationLat: 6.4541,
          destinationLng: 3.4258,
          estimatedDeliveryDate: now.add(const Duration(hours: 6)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 1.5,
        dimensions: '30cm x 25cm x 8cm',
        category: 'Electronics',
        description: 'Brand new smartphone with accessories. Express delivery within Lagos.',
        price: 4500,
        currency: 'NGN',
        escrowId: '',
        createdAt: now,
      ),

      // Parcel 7: Gift - Port Harcourt to Abuja
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Gift Shop PH',
          phoneNumber: '+234 816 012 3456',
          address: '44 Aba Road, Port Harcourt',
          email: 'giftshop@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Birthday Celebrant',
          phoneNumber: '+234 817 123 4567',
          address: '88 Maitama, Abuja',
          email: 'celebrant@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Port Harcourt',
          destination: 'Abuja',
          originLat: 4.8156,
          originLng: 7.0498,
          destinationLat: 9.0579,
          destinationLng: 7.4951,
          estimatedDeliveryDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 2.0,
        dimensions: '40cm x 40cm x 30cm (gift wrapped)',
        category: 'Other',
        description: 'Birthday gift package - fragile items inside. Gift wrapped, please handle carefully.',
        price: 9500,
        currency: 'NGN',
        escrowId: '',
        createdAt: now,
      ),

      // Parcel 8: Food - Abuja to Abuja (Same city, urgent)
      ParcelModel(
        id: '',
        sender: SenderDetailsModel(
          userId: userId,
          name: 'Fresh Foods Abuja',
          phoneNumber: '+234 818 234 5678',
          address: '22 Wuse Market, Abuja',
          email: 'freshfoods@example.com',
        ),
        receiver: ReceiverDetailsModel(
          name: 'Corporate Event',
          phoneNumber: '+234 819 345 6789',
          address: 'Transcorp Hilton, Abuja',
          email: 'events@example.com',
        ),
        route: RouteInformationModel(
          origin: 'Abuja',
          destination: 'Abuja',
          originLat: 9.0579,
          originLng: 7.4951,
          destinationLat: 9.0643,
          destinationLng: 7.4892,
          estimatedDeliveryDate: now.add(const Duration(hours: 4)).toIso8601String(),
        ),
        status: ParcelStatus.created,
        weight: 8.0,
        dimensions: '60cm x 40cm x 30cm (cooler box)',
        category: 'Food',
        description: 'Catering order for corporate event. Perishable items - must arrive within 4 hours!',
        price: 7500,
        currency: 'NGN',
        escrowId: 'ESCROW-${DateTime.now().millisecondsSinceEpoch + 2}',
        createdAt: now,
      ),
    ];
  }
}
