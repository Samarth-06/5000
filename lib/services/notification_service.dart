import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Farm notification service.
/// • Requests POST_NOTIFICATIONS permission on Android 13+
/// • Bridges Firebase push notifications to local display
/// • Exposes sendTest() for the settings screen
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _firebaseAvailable = false;

  // ── Android notification channel ─────────────────────────────────────────
  static const _channel = AndroidNotificationChannel(
    'farm_alerts',
    'Farm Alerts',
    description: 'Smart Farm — NDVI drops, pest advisories, irrigation alerts',
    importance: Importance.high,
    playSound: true,
  );

  // ── Init ─────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    // 1. Create the Android channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Initialize plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(initSettings);

    // 3. Request Android 13+ POST_NOTIFICATIONS permission via the plugin
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 4. Firebase Messaging bridge (optional — graceful if Firebase not configured)
    try {
      final messaging = FirebaseMessaging.instance;
      // Also request FCM permission (iOS + Android 13)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        final n = msg.notification;
        if (n == null) return;
        await show(id: n.hashCode, title: n.title ?? 'Farm Alert', body: n.body ?? '');
      });
      _firebaseAvailable = true;
    } catch (_) {
      _firebaseAvailable = false;
    }

    _initialized = true;
  }

  // ── FCM Token ────────────────────────────────────────────────────────────
  static Future<String?> getFcmToken() async {
    if (!_initialized) await init();
    if (!_firebaseAvailable) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  // ── Show a local notification ─────────────────────────────────────────────
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ── Test notification (from Settings screen) ──────────────────────────────
  static Future<void> sendTest() async {
    await show(
      id: 999,
      title: '🌾 Smart Farm Test',
      body: 'Notifications are working! Your farm alerts will appear here.',
    );
  }

  // ── Farm data alert logic ─────────────────────────────────────────────────
  static Future<void> checkAndAlert({
    required double ndvi,
    required double previousNdvi,
    required double soilMoisture,
    required double rainProbability,
    required List<String> pestAlerts,
  }) async {
    if (!_initialized) await init();

    // NDVI drop
    if (previousNdvi > 0 && ndvi < previousNdvi - 0.05) {
      await show(
        id: 1,
        title: '⚠️ NDVI Drop Detected',
        body:
            'Vegetation health dropped from ${previousNdvi.toStringAsFixed(2)} '
            'to ${ndvi.toStringAsFixed(2)}. Check crop condition.',
      );
    }

    // Irrigation needed
    if (soilMoisture < 30 && rainProbability < 30) {
      await show(
        id: 2,
        title: '💧 Irrigation Required',
        body:
            'Soil moisture is low (${soilMoisture.toStringAsFixed(0)}%) '
            'and rain is unlikely. Irrigate now.',
      );
    }

    // Heavy rain warning
    if (rainProbability > 70) {
      await show(
        id: 3,
        title: '🌧️ Heavy Rain Expected',
        body:
            'Rain probability is ${rainProbability.toStringAsFixed(0)}%. '
            'Delay irrigation and check drainage.',
      );
    }

    // Pest advisory
    if (pestAlerts.isNotEmpty) {
      await show(
        id: 4,
        title: '🐛 Pest Advisory',
        body: pestAlerts.first,
      );
    }
  }
}
