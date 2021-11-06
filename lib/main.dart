import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin? notificationManager;

  List<int> expected = [];

  @override
  void initState() {
    _init();
    super.initState();
  }

  void _init() async {
    notificationManager = FlutterLocalNotificationsPlugin();
    await notificationManager!.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: IOSInitializationSettings(),
        ), onSelectNotification: (String? payload) async {
      if (payload != null) {
        handleLocalNotification(payload);
      }
    });

    NotificationAppLaunchDetails? launchDetails =
        await notificationManager!.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      if (launchDetails.payload != null) {
        handleLocalNotification(launchDetails.payload!);
      }
    }
  }

  void handleLocalNotification(String payload) {}

  void _cancelAll() async {
    expected.clear();
    await notificationManager!.cancelAll();
    await _check();
  }

  Future<void> _check() async {
    List<int> currentIds = (await notificationManager!
            .pendingNotificationRequests())
        .map((e) => e.id)
        .toList()
      ..sort();
    print(currentIds);
    if (expected.isNotEmpty) {
      bool missings = false;
      for (int i in expected) {
        if (!currentIds.contains(i)) {
          print("$i is missing");
          missings = true;
        }
      }
      if (!missings) {
        print("all clear");
      }
    }
  }

  Future<void> _schedule(
      [Duration duration = const Duration(milliseconds: 0)]) async {
    const Duration interval = Duration(days: 1);

    const x = 20;

    List<DateTime> dates = [];

    DateTime now = DateTime.now();

    for (int i = 0; i < x; i++) {
      now = now.add(interval);
      dates.add(now);
    }

    await _check();

    for (int i = 0; i < dates.length; i++) {
      debugPrint("scheduling $i at ${dates[i]}");
      expected.add(i);
      await notificationManager!
          .zonedSchedule(
            i,
            "Test at $now",
            "Random body",
            tz.TZDateTime.from(dates[i], tz.local),
            const NotificationDetails(
                android: AndroidNotificationDetails(
              'channelId',
              'channelName',
              channelDescription: 'channelDescription',
              color: Colors.red,
              importance: Importance.max,
              priority: Priority.max,
            )),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true,
          )
          .then((_) => Future.delayed(duration));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: const Text("Check"),
                    onPressed: _check,
                  ),
                  const SizedBox(width: 50),
                  ElevatedButton(
                    child: const Text("Cancel All"),
                    onPressed: _cancelAll,
                  ),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                child: const Text("Schedule with await"),
                onPressed: _schedule,
              ),
              ElevatedButton(
                child: const Text("Schedule with await + 15ms"),
                onPressed: () => _schedule(const Duration(milliseconds: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
