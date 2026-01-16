import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_settings_entity.dart';

/// Repository interface for notification settings operations
abstract class NotificationSettingsRepository {
  /// Get notification settings for a user
  Future<Either<Failure, NotificationSettingsEntity>> getSettings(String userId);

  /// Update notification settings for a user
  Future<Either<Failure, void>> updateSettings(
    String userId,
    NotificationSettingsEntity settings,
  );

  /// Watch notification settings for real-time updates
  Stream<Either<Failure, NotificationSettingsEntity>> watchSettings(String userId);
}
