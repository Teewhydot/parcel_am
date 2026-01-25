import 'dart:async';
import '../../../../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/escrow_model.dart';
import '../../domain/exceptions/custom_exceptions.dart';
import '../../../escrow/domain/entities/escrow_status.dart';

abstract class EscrowRemoteDataSource {
  Stream<EscrowModel> watchEscrowStatus(String escrowId);
  Stream<EscrowModel?> watchEscrowByParcel(String parcelId);
  Future<EscrowModel> createEscrow(
    String parcelId,
    String senderId,
    String travelerId,
    double amount,
    String currency,
  );
  Future<EscrowModel> updateEscrowStatus(
    String escrowId,
    EscrowStatus status,
  );
  Future<EscrowModel> holdEscrow(String escrowId);
  Future<EscrowModel> releaseEscrow(String escrowId);
  Future<EscrowModel> cancelEscrow(String escrowId, String reason);
  Future<EscrowModel> getEscrow(String escrowId);
  Future<List<EscrowModel>> getUserEscrows(String userId);
}

class EscrowRemoteDataSourceImpl implements EscrowRemoteDataSource {
  final FirebaseFirestore firestore;

  EscrowRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<EscrowModel> watchEscrowStatus(String escrowId) {
    return firestore
        .collection('escrows')
        .doc(escrowId)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchEscrowStatus): $error', tag: 'EscrowRemoteDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'EscrowRemoteDataSource');
      }
    })
        .map((snapshot) {
      if (!snapshot.exists) {
        throw const NotFoundException('Escrow not found');
      }
      return EscrowModel.fromFirestore(snapshot);
    });
  }

  @override
  Stream<EscrowModel?> watchEscrowByParcel(String parcelId) {
    return firestore
        .collection('escrows')
        .where('parcelId', isEqualTo: parcelId)
        .limit(1)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchEscrowByParcel): $error', tag: 'EscrowRemoteDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'EscrowRemoteDataSource');
        Logger.logError('   Collection: escrows', tag: 'EscrowRemoteDataSource');
        Logger.logError('   Fields: parcelId (Ascending)', tag: 'EscrowRemoteDataSource');
        Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'EscrowRemoteDataSource');
      }
    })
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return EscrowModel.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<EscrowModel> createEscrow(
    String parcelId,
    String senderId,
    String travelerId,
    double amount,
    String currency,
  ) async {
    final escrowRef = firestore.collection('escrows').doc();

    final escrowData = {
      'parcelId': parcelId,
      'senderId': senderId,
      'travelerId': travelerId,
      'amount': amount,
      'currency': currency,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': {},
    };

    await escrowRef.set(escrowData);

    final createdDoc = await escrowRef.get();
    return EscrowModel.fromFirestore(createdDoc);
  }

  @override
  Future<EscrowModel> updateEscrowStatus(
    String escrowId,
    EscrowStatus status,
  ) async {
    final docRef = firestore.collection('escrows').doc(escrowId);

    final updateData = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == EscrowStatus.held) {
      updateData['heldAt'] = FieldValue.serverTimestamp();
    } else if (status == EscrowStatus.released) {
      updateData['releasedAt'] = FieldValue.serverTimestamp();
    }

    await docRef.update(updateData);

    final updatedDoc = await docRef.get();
    if (!updatedDoc.exists) {
      throw const NotFoundException('Escrow not found after update');
    }
    return EscrowModel.fromFirestore(updatedDoc);
  }

  @override
  Future<EscrowModel> holdEscrow(String escrowId) async {
    return updateEscrowStatus(escrowId, EscrowStatus.held);
  }

  @override
  Future<EscrowModel> releaseEscrow(String escrowId) async {
    return updateEscrowStatus(escrowId, EscrowStatus.released);
  }

  @override
  Future<EscrowModel> cancelEscrow(String escrowId, String reason) async {
    final docRef = firestore.collection('escrows').doc(escrowId);

    final updateData = {
      'status': EscrowStatus.cancelled.name,
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(updateData);

    final updatedDoc = await docRef.get();
    if (!updatedDoc.exists) {
      throw const NotFoundException('Escrow not found after cancellation');
    }
    return EscrowModel.fromFirestore(updatedDoc);
  }

  @override
  Future<EscrowModel> getEscrow(String escrowId) async {
    final doc = await firestore.collection('escrows').doc(escrowId).get();

    if (!doc.exists) {
      throw const NotFoundException('Escrow not found');
    }

    return EscrowModel.fromFirestore(doc);
  }

  @override
  Future<List<EscrowModel>> getUserEscrows(String userId) async {
    final snapshot = await firestore
        .collection('escrows')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final senderEscrows = snapshot.docs
        .map((doc) => EscrowModel.fromFirestore(doc))
        .toList();

    final travelerSnapshot = await firestore
        .collection('escrows')
        .where('travelerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final travelerEscrows = travelerSnapshot.docs
        .map((doc) => EscrowModel.fromFirestore(doc))
        .toList();

    final allEscrows = [...senderEscrows, ...travelerEscrows];
    allEscrows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allEscrows;
  }
}
