import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/visitor_notification.dart';

class VisitorNotificationRepository {
  VisitorNotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const _readIdsKey = 'ouedna.read_visitor_notification_ids';
  final SupabaseClient _client;

  Future<List<VisitorNotification>> getPublished({int limit = 50}) async {
    final rows = await _client
        .from('visitor_notifications')
        .select(
          'id, type, title, body, image_url, target_type, target_place_id, target_url, published_at',
        )
        .order('published_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(VisitorNotification.fromMap)
        .toList();
  }

  Future<Set<String>> readIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_readIdsKey)?.toSet() ?? <String>{};
  }

  Future<void> markRead(String notificationId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = await readIds();
    ids.add(notificationId);
    final recentIds = ids.take(300).toList(growable: false);
    await preferences.setStringList(_readIdsKey, recentIds);
  }

  Future<void> markAllRead(Iterable<String> notificationIds) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = await readIds();
    ids.addAll(notificationIds);
    await preferences.setStringList(
      _readIdsKey,
      ids.take(300).toList(growable: false),
    );
  }

  Stream<void> watchPublished() {
    final controller = StreamController<void>.broadcast();
    final channel = _client
        .channel('ouedna-visitor-notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'visitor_notifications',
          callback: (_) => controller.add(null),
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }
}
