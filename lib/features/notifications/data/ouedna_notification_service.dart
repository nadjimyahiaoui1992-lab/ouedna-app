import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/localization/ouedna_localization.dart';

const _androidChannel = AndroidNotificationChannel(
  'ouedna_updates',
  'تحديثات وادنا',
  description: 'تنبيهات الإصدارات والتحسينات المهمة في وادنا.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Must remain a top-level function so Android can invoke it while the app is
/// not in the foreground.
@pragma('vm:entry-point')
Future<void> ouednaFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase configuration is optional until google-services.json is added.
  }
}

class OuednaNotificationService {
  OuednaNotificationService._();

  static final instance = OuednaNotificationService._();

  final _updateActionController = StreamController<void>.broadcast();
  final _inboxActionController = StreamController<void>.broadcast();
  Stream<void> get updateActions => _updateActionController.stream;
  Stream<void> get inboxActions => _inboxActionController.stream;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Future<void> initialize(AppLanguageController languageController) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(ouednaFirebaseBackgroundHandler);

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == 'app_update') {
            _updateActionController.add(null);
          } else if (response.payload == 'visitor_notification') {
            _inboxActionController.add(null);
          }
        },
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      FirebaseMessaging.onMessage
          .listen((message) => _showForegroundMessage(message));
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenMessage);
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleOpenMessage(initialMessage);

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerDevice(token, languageController.language);
      }
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _registerDevice(token, languageController.language),
      );
    } catch (_) {
      // The tourism application remains usable when a notification provider is
      // not configured or the visitor declines notification permission.
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final isEssential = message.data['essential'] == true ||
        message.data['type'] == 'safety' ||
        message.data['type'] == 'app_update';
    if (!isEssential) {
      final preferences = await SharedPreferences.getInstance();
      if (!(preferences.getBool('ouedna.general_notifications_enabled') ??
          true)) {
        return;
      }
    }
    final isUpdate = message.data['type'] == 'app_update';
    final title = message.notification?.title ??
        (isUpdate ? 'يتوفر تحديث جديد لودنا' : 'جديد في وادنا');
    final body = message.notification?.body ??
        (isUpdate
            ? 'اضغط لفتح مركز التحديث وتثبيت الإصدار الجديد.'
            : 'اضغط لعرض التفاصيل.');

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ouedna_updates',
          'تحديثات وادنا',
          channelDescription: 'تنبيهات الإصدارات والتحسينات المهمة في وادنا.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: isUpdate ? 'app_update' : 'visitor_notification',
    );
  }

  void _handleOpenMessage(RemoteMessage message) {
    if (message.data['type'] == 'app_update') {
      _updateActionController.add(null);
    } else {
      _inboxActionController.add(null);
    }
  }

  Future<AuthorizationStatus?> requestPermission() async {
    if (!_initialized) return null;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus;
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerDevice(String token, AppLanguage language) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await Supabase.instance.client.functions.invoke(
        'register-push-device',
        body: {
          'token': token,
          'platform': 'android',
          'app_version': packageInfo.version,
          'language_code': language.code,
        },
      );
    } catch (_) {
      // Registration is retried automatically when FCM refreshes its token.
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _updateActionController.close();
    await _inboxActionController.close();
  }
}
