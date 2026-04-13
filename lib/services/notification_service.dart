import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
  AndroidNotificationDetails(
    'limit_channel',
    'Limit Alerts',
    channelDescription: 'Notifies when your expense limit is reached',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const NotificationDetails _notificationDetails =
  NotificationDetails(android: _androidDetails);

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showLimitReachedNotification({
    required String limitType,
    required double limitAmount,
    required String currency,
  }) async {
    await _notifications.show(
      1001,
      '⚠️ Expense Limit Reached!',
      'You have reached your $limitType limit of $currency${limitAmount.toStringAsFixed(0)}',
      _notificationDetails,
    );
  }

  static Future<void> showOverLimitCashOutNotifications({
    required String limitType,
    required double limitAmount,
    required double totalSpent,
    required String currency,
  }) async {
    final double overage = totalSpent - limitAmount;

    final List<Map<String, String>> messages = [
      {
        'title': '🚨 Over Limit! – Alert 1/4',
        'body': 'You are $currency${overage.toStringAsFixed(0)} over your $limitType limit!',
      },
      {
        'title': '🚨 Over Limit! – Alert 2/4',
        'body': 'Total spent: $currency${totalSpent.toStringAsFixed(0)} | Limit: $currency${limitAmount.toStringAsFixed(0)}',
      },
      {
        'title': '🚨 Over Limit! – Alert 3/4',
        'body': 'Please review your expenses and manage spending wisely.',
      },
      {
        'title': '🚨 Over Limit! – Alert 4/4',
        'body': 'You have exceeded your $limitType budget. Adjust your limit in Settings.',
      },
    ];

    for (int i = 0; i < messages.length; i++) {
      await Future.delayed(Duration(seconds: i * 2));
      await _notifications.show(
        2001 + i,
        messages[i]['title']!,
        messages[i]['body']!,
        _notificationDetails,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}