import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medihelp/pages/edit_reminder.dart';
import 'package:medihelp/pages/history.dart';
import 'package:medihelp/services/history_service.dart';
import 'package:medihelp/services/notification_service.dart';
import 'package:medihelp/services/reminder_service.dart';
import 'package:medihelp/services/setup/services_setup.dart';

import 'model/reminder.dart';
import 'model/took.dart';
import 'widgets/reminder_widget.dart';

void main() {
  setupServices();
  runApp(MyApp());
}

final getIt = GetIt.instance;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    getIt.get<NotificationService>().init(context);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange[600],
        accentColor: Colors.orange[300],
        textTheme: GoogleFonts.telexTextTheme(),
      ),
      initialRoute: MainPage.routeName,
      routes: {
        MainPage.routeName: (context) => MainPage(),
        EditReminder.routeName: (context) => EditReminder(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  static String routeName = '/';
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPage = 0;
  final _pageController = PageController();

  NotificationService notificationService = getIt.get<NotificationService>();
  ReminderService reminderService = getIt.get<ReminderService>();
  HistoryService historyService = getIt.get<HistoryService>();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page > 0.5 ? 1 : 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Scheduled notifications",
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            color: Colors.black,
            onPressed: () => _addReminder(context),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              AnimatedContainer(
                height: 48.0,
                duration: Duration(milliseconds: 400),
                curve: Curves.decelerate,
                alignment: _currentPage == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: (MediaQuery.of(context).size.width / 2) - 16.0,
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: Icon(
                        Icons.list,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        _pageController.animateToPage(0,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.decelerate);
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: Icon(
                        Icons.history,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        _pageController.animateToPage(1,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.decelerate);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: <Widget>[
          FutureBuilder(
            future: reminderService.getPendingReminders(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildEmptyScreen();
              }
              List<Reminder> _reminders = snapshot.data;
              return ListView(
                children: List.generate(_reminders.length, (index) {
                  var reminder = _reminders[index];
                  return Dismissible(
                    key: Key(reminder.id.toString()),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async =>
                        _confirmDismiss(context, reminder),
                    onDismissed: (direction) => _deleteReminder(reminder),
                    child: ReminderWidget(
                      reminder: reminder,
                      onTap: () => _editReminder(reminder),
                      onTake: () => _onTake(context, reminder),
                      onDelete: () => _deleteReminder(reminder),
                    ),
                  );
                }),
              );
            },
          ),
          History(),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _onTake(BuildContext context, Reminder reminder) {
    final time = DateTime.now();
    historyService.add(Took(reminder.id, time));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${reminder.label} took at ${time.toIso8601String()}")));
  }

  Future<bool> _confirmDismiss(context, reminder) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: 100,
            padding: EdgeInsets.all(16.0),
            width: double.infinity,
            color: Colors.blueGrey[600],
            child: Column(
              children: <Widget>[
                Text(
                  "Are you sure ?",
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          child: Text("No"),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          child: Text("Yes"),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Center _buildEmptyScreen() {
    return Center(
      child: Text(
        "Press + button to add",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
        ),
      ),
    );
  }

  void _editReminder(Reminder reminder) async {
    var result = await Navigator.pushNamed(
      context,
      EditReminder.routeName,
      arguments: reminder,
    );
    if (result != null) {
      if ((result as Reminder).deleted) {
        _deleteReminder(result);
      } else {
        notificationService.replaceSchedule(result);
        setState(() {
          reminderService.replaceReminder(reminder, result);
        });
      }
    }
  }

  void _deleteReminder(Reminder reminder) async {
    setState(() {
      reminderService.remove(reminder);
    });
  }

  Future<void> _addReminder(BuildContext context) async {
    print('add');
    var result = await Navigator.pushNamed(
      context,
      EditReminder.routeName,
      arguments: new Reminder(
        reminderService.uniqueId(),
        label: "",
        pills: 0,
        timeOfDay: new TimeOfDay(hour: 0, minute: 00),
      ),
    );
    if (result != null) {
      Reminder newReminder = result;
      setState(() {
        reminderService.add(newReminder);
      });
    }
  }
}
