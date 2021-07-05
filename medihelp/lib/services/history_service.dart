import 'package:medihelp/model/took.dart';

class HistoryService {
  List<Took> tooks = [];

  add(Took took) {
    tooks.add(took);
  }
}
