import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/features/manager/data/manager_settings_repository.dart';

enum ManagerSettingsStatus { loading, ready, saving, failure }

class ManagerSettingsState {
  const ManagerSettingsState(
      {required this.status,
      this.notificationsEnabled = true,
      this.reminderMinutes = 15,
      this.error});

  final ManagerSettingsStatus status;
  final bool notificationsEnabled;
  final int reminderMinutes;
  final String? error;
}

class ManagerSettingsCubit extends Cubit<ManagerSettingsState> {
  ManagerSettingsCubit({ManagerSettingsRepository? repository})
      : _repository = repository ?? ManagerSettingsRepository(),
        super(
            const ManagerSettingsState(status: ManagerSettingsStatus.loading));

  final ManagerSettingsRepository _repository;

  Future<void> load() async {
    try {
      final settings = await _repository.load();
      emit(ManagerSettingsState(
          status: ManagerSettingsStatus.ready,
          notificationsEnabled:
              settings['notifications_enabled'] as bool? ?? true,
          reminderMinutes: settings['reminder_minutes'] as int? ?? 15));
    } catch (error) {
      emit(ManagerSettingsState(
          status: ManagerSettingsStatus.failure, error: error.toString()));
    }
  }

  void setNotificationsEnabled(bool value) => emit(ManagerSettingsState(
      status: ManagerSettingsStatus.ready,
      notificationsEnabled: value,
      reminderMinutes: state.reminderMinutes));
  void setReminderMinutes(int value) => emit(ManagerSettingsState(
      status: ManagerSettingsStatus.ready,
      notificationsEnabled: state.notificationsEnabled,
      reminderMinutes: value));

  Future<void> save() async {
    emit(ManagerSettingsState(
        status: ManagerSettingsStatus.saving,
        notificationsEnabled: state.notificationsEnabled,
        reminderMinutes: state.reminderMinutes));
    try {
      await _repository.save(
          notificationsEnabled: state.notificationsEnabled,
          reminderMinutes: state.reminderMinutes);
      emit(ManagerSettingsState(
          status: ManagerSettingsStatus.ready,
          notificationsEnabled: state.notificationsEnabled,
          reminderMinutes: state.reminderMinutes));
    } catch (error) {
      emit(ManagerSettingsState(
          status: ManagerSettingsStatus.failure,
          notificationsEnabled: state.notificationsEnabled,
          reminderMinutes: state.reminderMinutes,
          error: error.toString()));
    }
  }
}
