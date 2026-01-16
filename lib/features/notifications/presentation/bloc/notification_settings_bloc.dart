import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

/// BLoC for managing notification settings state
class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, BaseState<NotificationSettingsData>> {
  final NotificationSettingsRepository _repository;

  NotificationSettingsBloc({
    required NotificationSettingsRepository repository,
  })  : _repository = repository,
        super(const InitialState<NotificationSettingsData>()) {
    on<LoadNotificationSettings>(_onLoadSettings);
    on<ToggleNotificationSetting>(_onToggleSetting);
    on<SaveNotificationSettings>(_onSaveSettings);
    on<ResetNotificationSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadNotificationSettings event,
    Emitter<BaseState<NotificationSettingsData>> emit,
  ) async {
    emit(const LoadingState<NotificationSettingsData>());

    final result = await _repository.getSettings(event.userId);

    result.fold(
      (failure) => emit(ErrorState<NotificationSettingsData>(
        errorMessage: failure.failureMessage,
      )),
      (settings) => emit(LoadedState<NotificationSettingsData>(
        data: NotificationSettingsData(settings: settings),
      )),
    );
  }

  void _onToggleSetting(
    ToggleNotificationSetting event,
    Emitter<BaseState<NotificationSettingsData>> emit,
  ) {
    final currentState = state;
    if (currentState is! LoadedState<NotificationSettingsData>) return;

    final currentData = currentState.data;
    if (currentData == null) return;

    final currentSettings = currentData.settings;
    NotificationSettingsEntity updatedSettings;

    switch (event.settingKey) {
      case 'chatMessages':
        updatedSettings = currentSettings.copyWith(chatMessages: event.value);
        break;
      case 'parcelUpdates':
        updatedSettings = currentSettings.copyWith(parcelUpdates: event.value);
        break;
      case 'escrowAlerts':
        updatedSettings = currentSettings.copyWith(escrowAlerts: event.value);
        break;
      case 'systemAnnouncements':
        updatedSettings = currentSettings.copyWith(systemAnnouncements: event.value);
        break;
      default:
        return;
    }

    emit(LoadedState<NotificationSettingsData>(
      data: NotificationSettingsData(
        settings: updatedSettings,
        hasChanges: true,
      ),
    ));
  }

  Future<void> _onSaveSettings(
    SaveNotificationSettings event,
    Emitter<BaseState<NotificationSettingsData>> emit,
  ) async {
    final currentState = state;
    if (currentState is! LoadedState<NotificationSettingsData>) return;

    final currentData = currentState.data;
    if (currentData == null) return;

    // Show saving state while keeping data
    emit(AsyncLoadingState<NotificationSettingsData>(data: currentData));

    final result = await _repository.updateSettings(
      event.userId,
      currentData.settings,
    );

    result.fold(
      (failure) => emit(AsyncErrorState<NotificationSettingsData>(
        data: currentData,
        errorMessage: failure.failureMessage,
      )),
      (_) => emit(LoadedState<NotificationSettingsData>(
        data: currentData.copyWith(hasChanges: false),
      )),
    );
  }

  void _onResetSettings(
    ResetNotificationSettings event,
    Emitter<BaseState<NotificationSettingsData>> emit,
  ) {
    emit(LoadedState<NotificationSettingsData>(
      data: NotificationSettingsData(
        settings: NotificationSettingsEntity.defaultSettings(),
        hasChanges: true,
      ),
    ));
  }
}
