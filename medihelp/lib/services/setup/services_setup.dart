import 'package:get_it/get_it.dart';

import '../history_service.dart';
import '../notification_service.dart';
import '../reminder_service.dart';

void setupServices() {
  GetIt.I.registerSingleton<NotificationService>(NotificationService());
  GetIt.I.registerSingleton<HistoryService>(HistoryService());
  GetIt.I.registerSingleton<ReminderService>(ReminderService());
}
