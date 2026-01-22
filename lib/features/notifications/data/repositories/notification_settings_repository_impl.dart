import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import '../models/notification_settings_model.dart';

/// Implementation of NotificationSettingsRepository using Firestore
class NotificationSettingsRepositoryImpl implements NotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  NotificationSettingsRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Future<Either<Failure, NotificationSettingsEntity>> getSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // Return default settings if user document doesn't exist
        return Right(NotificationSettingsEntity.defaultSettings());
      }

      final settings = NotificationSettingsModel.fromFirestore(doc.data());
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(failureMessage: 'Failed to load notification settings'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(
    String userId,
    NotificationSettingsEntity settings,
  ) async {
    try {
      final model = NotificationSettingsModel.fromEntity(settings);

      await _firestore.collection('users').doc(userId).update(
        model.toFirestoreUpdate(),
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: 'Failed to save notification settings'));
    }
  }

  @override
  Stream<Either<Failure, NotificationSettingsEntity>> watchSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      try {
        if (!snapshot.exists) {
          return Right(NotificationSettingsEntity.defaultSettings());
        }

        final settings = NotificationSettingsModel.fromFirestore(snapshot.data());
        return Right(settings);
      } catch (e) {
        return Left(ServerFailure(failureMessage: 'Failed to watch notification settings'));
      }
    });
  }
}
