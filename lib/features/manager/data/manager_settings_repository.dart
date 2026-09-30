import 'package:lelahanoi/core/data/firestore_data_source.dart';
import 'package:lelahanoi/core/services/notification_service.dart';

class ManagerSettingsRepository {
  ManagerSettingsRepository({FirestoreDataSource? dataSource})
      : _dataSource = dataSource ?? FirestoreDataSource();

  final FirestoreDataSource _dataSource;

  Future<Map<String, dynamic>> load() => _dataSource.getManagerSettings();

  Future<void> save(
      {required bool notificationsEnabled,
      required int reminderMinutes}) async {
    await _dataSource.saveManagerSettings({
      'notifications_enabled': notificationsEnabled,
      'reminder_minutes': reminderMinutes
    });
    if (!notificationsEnabled) await NotificationService.cancelAll();
  }
}
