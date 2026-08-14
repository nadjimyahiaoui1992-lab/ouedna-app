import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mesures privées et agrégées. L'identifiant est aléatoire, stocké seulement
/// sur l'appareil et ne correspond ni à un compte, ni à un numéro, ni à une
/// localisation. Il sert uniquement à éviter de compter plusieurs fois la
/// même installation au cours d'une journée.
class AppMetricsService {
  AppMetricsService({
    required SharedPreferences preferences,
    SupabaseClient? client,
  })  : _preferences = preferences,
        _client = client;

  static const _installationIdKey = 'ouedna_analytics_installation_id';

  final SharedPreferences _preferences;
  final SupabaseClient? _client;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> recordStartup({required String localeCode}) async {
    final installationId = _installationId();
    final packageInfo = await PackageInfo.fromPlatform();
    final eventParameters = <String, Object>{
      'app_version': packageInfo.version,
      'distribution': const bool.fromEnvironment('OUEDNA_DIRECT_BUILD')
          ? 'direct'
          : 'play',
    };

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'ouedna_app_session',
        parameters: eventParameters,
      );
    } catch (_) {
      // Firebase reste facultatif tant que la configuration Analytics n'est
      // pas activée dans le projet Firebase.
    }

    final client = _client;
    if (client == null) return;
    try {
      await client.functions.invoke(
        'track-app-activity',
        body: {
          'installation_id': installationId,
          'app_version': packageInfo.version,
          'locale_code': localeCode,
        },
      );
    } catch (_) {
      // Le guide reste fonctionnel hors ligne. Une prochaine ouverture
      // réenregistrera l'activité quotidienne.
    }
  }

  String _installationId() {
    final existing = _preferences.getString(_installationIdKey);
    if (existing != null && _uuidV4Pattern.hasMatch(existing)) return existing;
    final created = _newUuidV4();
    _preferences.setString(_installationIdKey, created);
    return created;
  }

  static final _uuidV4Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
