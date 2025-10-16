import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    // Request permissions (Android 13+ and iOS)
    await _requestPermissionsIfNeeded();

    // Create channels
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      AppConstants.orderNotificationChannel,
      'Order Updates',
      description: 'Notifications for order status updates',
      importance: Importance.high,
    );
    const AndroidNotificationChannel promotionChannel = AndroidNotificationChannel(
      AppConstants.promotionNotificationChannel,
      'Promotions',
      description: 'Promotional notifications',
      importance: Importance.high,
    );
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      AppConstants.systemNotificationChannel,
      'System',
      description: 'System notifications',
      importance: Importance.high,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(orderChannel);
    await android?.createNotificationChannel(promotionChannel);
    await android?.createNotificationChannel(systemChannel);

    _initialized = true;
  }

  static Future<void> _requestPermissionsIfNeeded() async {
    try {
      // Android 13+ requires runtime permission
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.areNotificationsEnabled();
        if (granted != true) {
          await androidImpl.requestNotificationsPermission();
        }
      }

      // iOS permissions
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[LocalNotificationService] Permission request error: $e');
      }
    }
  }

  static Future<void> showOrderUpdate({required int orderId, required String title, required String body}) async {
    await initialize();
    final androidDetails = AndroidNotificationDetails(
      AppConstants.orderNotificationChannel,
      'Order Updates',
      channelDescription: 'Order update notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(orderId, title, body, details, payload: 'order:$orderId');
  }

  static Future<void> showBasic({required int id, required String title, required String body}) async {
    await initialize();
    final androidDetails = AndroidNotificationDetails(
      AppConstants.systemNotificationChannel,
      'System',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}


