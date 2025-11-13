import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/escrow_model.dart';
import '../../domain/entities/escrow_entity.dart';
import '../../domain/exceptions/custom_exceptions.dart';

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
  Future<EscrowModel> cancelEscrow(String escrowId);
  Future<EscrowModel> getEscrow(String escrowId);
}

class EscrowRemoteDataSourceImpl implements EscrowRemoteDataSource {
  final FirebaseFirestore firestore;

  EscrowRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<EscrowModel> watchEscrowStatus(String escrowId) {
    try {
      return firestore
          .collection('escrows')
          .doc(escrowId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          throw ServerException();
        }
        return EscrowModel.fromFirestore(snapshot);
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<EscrowModel?> watchEscrowByParcel(String parcelId) {
    try {
      return firestore
          .collection('escrows')
          .where('parcelId', isEqualTo: parcelId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }
        return EscrowModel.fromFirestore(snapshot.docs.first);
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<EscrowModel> createEscrow(
    String parcelId,
    String senderId,
    String travelerId,
    double amount,
    String currency,
  ) async {
    try {
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
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<EscrowModel> updateEscrowStatus(
    String escrowId,
    EscrowStatus status,
  ) async {
    try {
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
        throw ServerException();
      }
      return EscrowModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
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
  Future<EscrowModel> cancelEscrow(String escrowId) async {
    return updateEscrowStatus(escrowId, EscrowStatus.cancelled);
  }

  @override
  Future<EscrowModel> getEscrow(String escrowId) async {
    try {
      final doc = await firestore.collection('escrows').doc(escrowId).get();

      if (!doc.exists) {
        throw ServerException();
      }

      return EscrowModel.fromFirestore(doc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }
}
