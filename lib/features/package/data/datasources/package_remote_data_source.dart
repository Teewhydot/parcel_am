import 'dart:async';
import '../../../../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        .handleError((error) {
      Logger.logError('Firestore Error (getPackageStream): $error', tag: 'PackageRemoteDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'PackageRemoteDataSource');
      }
    })
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Package not found');
      }
      return {'id': snapshot.id, ...snapshot.data()!};
    });
  }

  @override
  Future<void> releaseEscrow({
    required String packageId,
    required String transactionId,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        final packageRef = firestore.collection('packages').doc(packageId);
        final packageSnapshot = await transaction.get(packageRef);

        if (!packageSnapshot.exists) {
          throw Exception('Package not found');
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
    } catch (e) {
      throw Exception('Failed to release escrow: $e');
    }
  }

  @override
  Future<String> createDispute({
    required String packageId,
    required String transactionId,
    required String reason,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to create dispute: $e');
    }
  }

  @override
  Future<void> confirmDelivery({
    required String packageId,
    required String confirmationCode,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        final packageRef = firestore.collection('packages').doc(packageId);
        final packageSnapshot = await transaction.get(packageRef);

        if (!packageSnapshot.exists) {
          throw Exception('Package not found');
        }

        transaction.update(packageRef, {
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
          'confirmationCode': confirmationCode,
          'progress': 100,
        });
      });
    } catch (e) {
      throw Exception('Failed to confirm delivery: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getActivePackagesStream(String userId) {
    return firestore
        .collection('packages')
        .where('senderId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted', 'in_transit', 'out_for_delivery'])
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (getActivePackagesStream): $error', tag: 'PackageRemoteDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'PackageRemoteDataSource');
        Logger.logError('   Collection: packages', tag: 'PackageRemoteDataSource');
        Logger.logError('   Fields: senderId (Ascending), status (Ascending)');
        Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'PackageRemoteDataSource');
      }
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }
}
