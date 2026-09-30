import 'package:lelahanoi/core/data/firestore_data_source.dart';
import 'package:lelahanoi/core/l10n/app_strings.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/services/notification_service.dart';

class ManagerReminderService {
  ManagerReminderService({FirestoreDataSource? dataSource})
      : _dataSource = dataSource ?? FirestoreDataSource();

  final FirestoreDataSource _dataSource;

  Future<void> sync(List<OrderModel> orders, AppStrings t) async {
    final settings = await _dataSource.getManagerSettings();
    if (!(settings['notifications_enabled'] as bool? ?? true)) return;
    final leadMinutes = settings['reminder_minutes'] as int? ?? 15;

    for (final order in orders) {
      if (order.status == OrderStatus.completed ||
          order.status == OrderStatus.cancelled) {
        continue;
      }
      final scheduledFor = order.orderType == OrderType.pickup
          ? order.pickupTime?.subtract(Duration(minutes: leadMinutes))
          : order.shipTime?.subtract(Duration(minutes: leadMinutes));
      if (scheduledFor == null) continue;

      final isPickup = order.orderType == OrderType.pickup;
      await NotificationService.scheduleManagerReminder(
        orderId: order.id,
        title: isPickup ? t.pickupReminderTitle : t.shipReminderTitle,
        body:
            '${isPickup ? t.pickupReminderBody : t.shipReminderBody} ${order.userName}',
        scheduledFor: scheduledFor,
      );
    }
  }
}
