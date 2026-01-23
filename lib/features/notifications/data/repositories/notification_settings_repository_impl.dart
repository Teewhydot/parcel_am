import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import '../models/notification_settings_model.dart';

/// Implementation of NotificationSettingsRepository using Firestore
class NotificationSettingsRepositoryImpl implements NotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  NotificationSettingsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? GetIt.instance<FirebaseFirestore>();

  @override
  Future<Either<Failure, NotificationSettingsEntity>> getSettings(String userId) {
    return ErrorHandler.handle(
      () async {
        final doc = await _firestore.collection('users').doc(userId).get();

        if (!doc.exists) {
          // Return default settings if user document doesn't exist
          return NotificationSettingsEntity.defaultSettings();
        }

        return NotificationSettingsModel.fromFirestore(doc.data());
      },
      operationName: 'getSettings',
    );
  }

  @override
  Future<Either<Failure, void>> updateSettings(
    String userId,
    NotificationSettingsEntity settings,
  ) {
    return ErrorHandler.handle(
      () async {
        final model = NotificationSettingsModel.fromEntity(settings);

        await _firestore.collection('users').doc(userId).update(
          model.toFirestoreUpdate(),
        );
      },
      operationName: 'updateSettings',
    );
  }

  @override
  Stream<Either<Failure, NotificationSettingsEntity>> watchSettings(String userId) {
    return ErrorHandler.handleStream(
      () => _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return NotificationSettingsEntity.defaultSettings();
        }
        return NotificationSettingsModel.fromFirestore(snapshot.data());
      }),
      operationName: 'watchSettings',
    );
  }
}
