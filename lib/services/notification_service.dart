import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Farm notification service — sends local alerts for NDVI drop, pest, rain, irrigation.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _firebaseMessagingAvailable = false;

  static FirebaseMessaging? _tryMessagingInstance() {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize the notification plugin.
  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final messaging = _tryMessagingInstance();
    if (messaging != null) {
      try {
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          final notification = message.notification;
          if (notification == null) return;
          await show(
            id: notification.hashCode,
            title: notification.title ?? 'Farm Alert',
            body: notification.body ?? '',
          );
        });
        _firebaseMessagingAvailable = true;
      } catch (_) {
        _firebaseMessagingAvailable = false;
      }
    }

    _initialized = true;
  }

  static Future<String?> getFcmToken() async {
    if (!_initialized) await init();
    if (!_firebaseMessagingAvailable) return null;
    final messaging = _tryMessagingInstance();
    if (messaging == null) return null;
    try {
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Show a local notification.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String channelId = 'farm_alerts',
    String channelName = 'Farm Alerts',
  }) async {
    if (!_initialized) await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Check farm data and trigger appropriate alerts.
  static Future<void> checkAndAlert({
    required double ndvi,
    required double previousNdvi,
    required double soilMoisture,
    required double rainProbability,
    required List<String> pestAlerts,
  }) async {
    // NDVI drop alert
    if (previousNdvi > 0 && ndvi < previousNdvi - 0.05) {
      await show(
        id: 1,
        title: '⚠️ NDVI Drop Detected',
        body:
            'Vegetation health dropped from ${previousNdvi.toStringAsFixed(2)} to ${ndvi.toStringAsFixed(2)}. Check crop condition.',
      );
    }

    // Irrigation alert
    if (soilMoisture < 30 && rainProbability < 30) {
      await show(
        id: 2,
        title: '💧 Irrigation Required',
        body:
            'Soil moisture is low (${soilMoisture.toStringAsFixed(0)}%) and rain unlikely. Irrigate now.',
      );
    }

    // Rain warning
    if (rainProbability > 70) {
      await show(
        id: 3,
        title: '🌧️ Heavy Rain Expected',
        body:
            'Rain probability is ${rainProbability.toStringAsFixed(0)}%. Delay irrigation and ensure drainage.',
      );
    }

    // Pest alerts
    if (pestAlerts.isNotEmpty) {
      await show(id: 4, title: '🐛 Pest Advisory', body: pestAlerts.first);
    }
  }
}
