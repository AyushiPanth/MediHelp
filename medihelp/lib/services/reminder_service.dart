import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:medihelp/model/reminder.dart';

import 'notification_service.dart';

class ReminderService {
  NotificationService notificationService = GetIt.I.get<NotificationService>();

  List<Reminder> _reminders = [];

  Future<List<Reminder>> getPendingReminders() async {
    List<PendingNotificationRequest> pendingRequests =
        await notificationService.getPending();

    return pendingRequests != null
        ? pendingRequests.map((e) => Reminder.fromJson(e.payload)).toList()
        : [];
  }

  int uniqueId() {
    int maxId = _reminders.isEmpty
        ? 1
        : _reminders
            .map((it) => it.id)
            .toList()
            .reduce((current, next) => current > next ? current : next);
    return maxId + 1;
  }

  void replaceReminder(Reminder oldOne, Reminder newOne) {
    _reminders.remove(oldOne);
    _reminders.add(newOne);
  }

  void remove(Reminder reminder) {
    _reminders.remove(reminder);
    notificationService.cancel(reminder);
  }

  void add(Reminder newReminder) {
    notificationService.scheduleNotification(newReminder);
    _reminders.add(newReminder);
  }
}
