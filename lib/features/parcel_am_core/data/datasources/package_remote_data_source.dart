import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/exceptions/custom_exceptions.dart';

abstract class PackageRemoteDataSource {
  Stream<Map<String, dynamic>> getPackageStream(String packageId);
  Future<void> releaseEscrow({
    required String packageId,
    required String transactionId,
  });
  Future<String> createDispute({
    required String packageId,
    required String transactionId,
    required String reason,
  });
  Future<void> confirmDelivery({
    required String packageId,
    required String confirmationCode,
  });
  Stream<List<Map<String, dynamic>>> getActivePackagesStream(String userId);
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final FirebaseFirestore firestore;

  PackageRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<Map<String, dynamic>> getPackageStream(String packageId) {
    return firestore
        .collection('packages')
        .doc(packageId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw const NotFoundException('Package not found');
      }
      return {'id': snapshot.id, ...snapshot.data()!};
    });
  }

  @override
  Future<void> releaseEscrow({
    required String packageId,
    required String transactionId,
  }) async {
    await firestore.runTransaction((transaction) async {
      final packageRef = firestore.collection('packages').doc(packageId);
      final packageSnapshot = await transaction.get(packageRef);

      if (!packageSnapshot.exists) {
        throw const NotFoundException('Package not found');
      }

      final paymentInfo = packageSnapshot.data()!['paymentInfo'] as Map<String, dynamic>?;

      if (paymentInfo == null || !paymentInfo['isEscrow']) {
        throw Exception('No escrow payment found for this package');
      }

      transaction.update(packageRef, {
        'paymentInfo.escrowStatus': 'released',
        'paymentInfo.escrowReleaseDate': FieldValue.serverTimestamp(),
      });

      final transactionRef = firestore.collection('transactions').doc(transactionId);
      transaction.update(transactionRef, {
        'status': 'released',
        'releasedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<String> createDispute({
    required String packageId,
    required String transactionId,
    required String reason,
  }) async {
    final disputeRef = await firestore.collection('disputes').add({
      'packageId': packageId,
      'transactionId': transactionId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await firestore.runTransaction((transaction) async {
      final packageRef = firestore.collection('packages').doc(packageId);
      transaction.update(packageRef, {
        'paymentInfo.escrowStatus': 'disputed',
        'disputeId': disputeRef.id,
      });

      final transactionRef = firestore.collection('transactions').doc(transactionId);
      transaction.update(transactionRef, {
        'status': 'disputed',
        'disputeId': disputeRef.id,
      });
    });

    return disputeRef.id;
  }

  @override
  Future<void> confirmDelivery({
    required String packageId,
    required String confirmationCode,
  }) async {
    await firestore.runTransaction((transaction) async {
      final packageRef = firestore.collection('packages').doc(packageId);
      final packageSnapshot = await transaction.get(packageRef);

      if (!packageSnapshot.exists) {
        throw const NotFoundException('Package not found');
      }

      transaction.update(packageRef, {
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'confirmationCode': confirmationCode,
        'progress': 100,
      });
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getActivePackagesStream(String userId) {
    return firestore
        .collection('packages')
        .where('senderId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted', 'in_transit', 'out_for_delivery'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }
}
