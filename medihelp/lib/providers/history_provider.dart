import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:medihelp/model/reminder.dart';
import 'package:medihelp/model/took.dart';
import 'package:medihelp/services/history_service.dart';
import 'package:medihelp/services/reminder_service.dart';

class HistoryProvider with ChangeNotifier {
  HistoryService historyService = GetIt.I.get<HistoryService>();
  ReminderService reminderService = GetIt.I.get<ReminderService>();

  List<Took> get tooks => historyService.tooks;

  get tooksIds => tooks.map((element) => element.id);

  bool hasBeenTaken(id) => tooksIds.contains(id);

  Future<List<Reminder>> takenReminders() async {
    final allPending = await reminderService.getPendingReminders();
    return allPending.where((element) => hasBeenTaken(element.id)).toList();
  }

  addToHistory(int id, DateTime dateTime) {
    historyService.tooks.add(Took(id, dateTime));
    notifyListeners();
  }
}
