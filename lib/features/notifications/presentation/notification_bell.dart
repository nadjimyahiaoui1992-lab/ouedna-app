import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../routing/domain/routing_service.dart';
import '../data/visitor_notification_repository.dart';
import 'notification_center_page.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.repository,
    required this.favorites,
    this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _notifications = VisitorNotificationRepository();
  StreamSubscription<void>? _publishedSubscription;
  StreamSubscription<void>? _localSubscription;
  int _unreadCount = 0;
  int _refreshToken = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _publishedSubscription =
        _notifications.watchPublished().listen((_) => _refreshUnread());
    _localSubscription =
        _notifications.watchLocalChanges().listen((_) => _refreshUnread());
  }

  @override
  void dispose() {
    _publishedSubscription?.cancel();
    _localSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    final token = ++_refreshToken;
    try {
      final result = await Future.wait([
        _notifications.getPublished(limit: 60),
        _notifications.readIds(),
        _notifications.hiddenIds(),
      ]);
      final items = result[0] as List;
      final readIds = result[1] as Set<String>;
      final hiddenIds = result[2] as Set<String>;
      final unread = items
          .where((item) =>
              !hiddenIds.contains(item.id) && !readIds.contains(item.id))
          .length;
      if (mounted && token == _refreshToken) {
        setState(() => _unreadCount = unread);
      }
    } catch (_) {
      // The home page remains available if notifications are offline.
    }
  }

  Future<void> _openCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterPage(
          repository: widget.repository,
          favorites: widget.favorites,
          routingService: widget.routingService,
        ),
      ),
    );
    await _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = _unreadCount > 99 ? '99+' : _unreadCount.toString();
    return Semantics(
      label: _unreadCount == 0
          ? 'الإشعارات'
          : 'الإشعارات، $_unreadCount غير مقروءة',
      button: true,
      child: IconButton(
        tooltip: 'الإشعارات',
        onPressed: _openCenter,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 27),
            if (_unreadCount > 0)
              PositionedDirectional(
                top: -7,
                end: -9,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeLabel,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
