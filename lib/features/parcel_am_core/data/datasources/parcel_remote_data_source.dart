import 'dart:async';
import '../../../../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parcel_model.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/exceptions/custom_exceptions.dart';

abstract class ParcelRemoteDataSource {
  Stream<ParcelModel> watchParcelStatus(String parcelId);
  Stream<List<ParcelModel>> watchUserParcels(String userId, {ParcelStatus? status});
  Stream<List<ParcelModel>> watchUserAcceptedParcels(String userId);
  Future<ParcelModel> createParcel(ParcelModel parcel);
  Future<ParcelModel> updateParcel(String parcelId, Map<String, dynamic> data);
  Future<ParcelModel> updateParcelStatus(String parcelId, ParcelStatus status);
  Future<ParcelModel> assignTraveler(String parcelId, String travelerId);
  Future<ParcelModel> getParcel(String parcelId);
  Future<List<ParcelModel>> getUserParcels(String userId, {ParcelStatus? status});
  Future<List<ParcelModel>> getParcelsByUser(String userId);
  Future<List<ParcelModel>> getAvailableParcels();
  Stream<List<ParcelModel>> watchAvailableParcels();
}

class ParcelRemoteDataSourceImpl implements ParcelRemoteDataSource {
  final FirebaseFirestore firestore;

  ParcelRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<ParcelModel> watchParcelStatus(String parcelId) {
    try {
      return firestore
          .collection('parcels')
          .doc(parcelId)
          .snapshots()
          .handleError((error) {
        Logger.logError('Firestore Error (watchParcelStatus): $error', tag: 'ParcelRemoteDataSource');
        if (error.toString().contains('index')) {
          Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'ParcelRemoteDataSource');
        }
      })
          .map((snapshot) {
        if (!snapshot.exists) {
          throw ServerException();
        }
        return ParcelModel.fromFirestore(snapshot);
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<List<ParcelModel>> watchUserParcels(String userId, {ParcelStatus? status}) {
    try {
      var query = firestore
          .collection('parcels')
          .where('sender.userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }

      return query.snapshots().handleError((error) {
        Logger.logError('Firestore Error (watchUserParcels): $error', tag: 'ParcelRemoteDataSource');
        if (error.toString().contains('index')) {
          Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Collection: parcels', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Fields: sender.userId (Ascending), createdAt (Descending)');
          if (status != null) {
            Logger.logError('   Additional field: status (Ascending)', tag: 'ParcelRemoteDataSource');
          }
          Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'ParcelRemoteDataSource');
        }
      }).map((snapshot) {
        return snapshot.docs
            .map((doc) => ParcelModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<List<ParcelModel>> watchUserAcceptedParcels(String userId) {
    try {
      return firestore
          .collection('parcels')
          .where('travelerId', isEqualTo: userId)
          .orderBy('lastStatusUpdate', descending: true)
          .snapshots()
          .handleError((error) {
        Logger.logError('Firestore Error (watchUserAcceptedParcels): $error', tag: 'ParcelRemoteDataSource');
        if (error.toString().contains('index')) {
          Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Collection: parcels', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Fields: travelerId (Ascending), lastStatusUpdate (Descending)', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'ParcelRemoteDataSource');
        }
      }).map((snapshot) {
        return snapshot.docs
            .map((doc) => ParcelModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ParcelModel> createParcel(ParcelModel parcel) async {
    try {
      final parcelRef = firestore.collection('parcels').doc();
      final parcelData = parcel.toJson();
      parcelData['createdAt'] = FieldValue.serverTimestamp();

      await parcelRef.set(parcelData);

      final createdDoc = await parcelRef.get();
      return ParcelModel.fromFirestore(createdDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ParcelModel> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = firestore.collection('parcels').doc(parcelId);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(data);

      final updatedDoc = await docRef.get();
      if (!updatedDoc.exists) {
        throw ServerException();
      }
      return ParcelModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ParcelModel> updateParcelStatus(
    String parcelId,
    ParcelStatus status,
  ) async {
    try {
      final docRef = firestore.collection('parcels').doc(parcelId);

      // Use Firestore transaction for atomic updates
      return await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw ServerException();
        }

        final statusKey = status.toJson();
        final timestamp = FieldValue.serverTimestamp();

        final updateData = {
          'status': statusKey,
          'updatedAt': timestamp,
          'lastStatusUpdate': timestamp,
          'metadata.deliveryStatusHistory.$statusKey': timestamp,
        };

        transaction.update(docRef, updateData);

        // Fetch updated document after transaction
        final updatedDoc = await docRef.get();
        if (!updatedDoc.exists) {
          throw ServerException();
        }
        return ParcelModel.fromFirestore(updatedDoc);
      });
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ParcelModel> assignTraveler(
    String parcelId,
    String travelerId,
  ) async {
    try {
      final docRef = firestore.collection('parcels').doc(parcelId);

      await docRef.update({
        'travelerId': travelerId,
        'status': ParcelStatus.paid.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await docRef.get();
      if (!updatedDoc.exists) {
        throw ServerException();
      }
      return ParcelModel.fromFirestore(updatedDoc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<ParcelModel> getParcel(String parcelId) async {
    try {
      final doc = await firestore.collection('parcels').doc(parcelId).get();

      if (!doc.exists) {
        throw ServerException();
      }

      return ParcelModel.fromFirestore(doc);
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<ParcelModel>> getUserParcels(String userId, {ParcelStatus? status}) async {
    try {
      var query = firestore
          .collection('parcels')
          .where('sender.userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ParcelModel.fromFirestore(doc))
          .toList();
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<ParcelModel>> getParcelsByUser(String userId) async {
    return getUserParcels(userId);
  }

  @override
  Future<List<ParcelModel>> getAvailableParcels() async {
    try {
      final query = firestore
          .collection('parcels')
          .where('status', isEqualTo: ParcelStatus.created.toJson())
          .orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ParcelModel.fromFirestore(doc))
          .toList();
    } on FirebaseException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<List<ParcelModel>> watchAvailableParcels() {
    try {
      return firestore
          .collection('parcels')
          .where('status', isEqualTo: ParcelStatus.created.toJson())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        Logger.logError('Firestore Error (watchAvailableParcels): $error', tag: 'ParcelRemoteDataSource');
        if (error.toString().contains('index')) {
          Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Collection: parcels', tag: 'ParcelRemoteDataSource');
          Logger.logError('   Fields: status (Ascending), createdAt (Descending)');
          Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'ParcelRemoteDataSource');
        }
      }).map((snapshot) {
        return snapshot.docs
            .map((doc) => ParcelModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw ServerException();
    }
  }
}
