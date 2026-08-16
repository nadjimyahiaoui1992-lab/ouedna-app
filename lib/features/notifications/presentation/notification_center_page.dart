import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_service.dart';
import '../../updates/presentation/update_center_page.dart';
import '../data/visitor_notification_repository.dart';
import '../domain/entities/visitor_notification.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({
    super.key,
    required this.repository,
    required this.favorites,
    this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final _notifications = VisitorNotificationRepository();
  StreamSubscription<void>? _subscription;
  List<VisitorNotification> _items = const [];
  Set<String> _readIds = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _subscription = _notifications.watchPublished().listen((_) => _load());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        _notifications.getPublished(),
        _notifications.readIds(),
      ]);
      if (mounted) {
        setState(() {
          _items = result[0] as List<VisitorNotification>;
          _readIds = result[1] as Set<String>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _notifications.markAllRead(_items.map((item) => item.id));
    if (mounted) {
      setState(() => _readIds = _items.map((item) => item.id).toSet());
    }
  }

  Future<void> _deletePrevious() async {
    if (_items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الإشعارات السابقة؟'),
        content: const Text(
          'ستختفي هذه الإشعارات من جهازك فقط. لن يتم حذفها من Supabase أو من أجهزة المستخدمين الآخرين.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _notifications.dismissAll(_items.map((item) => item.id));
    if (mounted) {
      setState(() {
        _items = const [];
        _readIds = const {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإشعارات السابقة من جهازك.')),
      );
    }
  }

  Future<void> _open(VisitorNotification item) async {
    if (!_readIds.contains(item.id)) {
      await _notifications.markRead(item.id);
      if (mounted) setState(() => _readIds = {..._readIds, item.id});
    }
    if (!mounted) return;

    switch (item.target) {
      case VisitorNotificationTarget.update:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpdateCenterPage()),
        );
        return;
      case VisitorNotificationTarget.place:
        final repository = widget.repository;
        if (repository == null || item.targetPlaceId == null) return;
        final place =
            await repository.getPublishedPlaceById(item.targetPlaceId!);
        if (!mounted || place == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceDetailsPage(
              place: place,
              repository: repository,
              favorites: widget.favorites,
              routingService: widget.routingService,
            ),
          ),
        );
        return;
      case VisitorNotificationTarget.url:
        final url = Uri.tryParse(item.targetUrl ?? '');
        if (url != null) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        return;
      case VisitorNotificationTarget.none:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !_readIds.contains(item.id)).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('قراءة الكل'),
            ),
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'حذف الإشعارات السابقة',
              onPressed: _deletePrevious,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const _EmptyNotifications()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _NotificationTile(
                        item: item,
                        isRead: _readIds.contains(item.id),
                        onTap: () => _open(item),
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  final VisitorNotification item;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _styleFor(item.type, scheme);
    return Material(
      color: isRead ? scheme.surface : style.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isRead ? scheme.outlineVariant : style.color.withOpacity(.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: style.color.withOpacity(.14),
                    foregroundColor: style.color,
                    backgroundImage: item.imageUrl?.isNotEmpty == true
                        ? NetworkImage(item.imageUrl!)
                        : null,
                    child: item.imageUrl?.isNotEmpty == true
                        ? null
                        : Icon(style.icon),
                  ),
                  if (!isRead)
                    PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: scheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, height: 1.35),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _relativeTime(item.publishedAt),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.target != VisitorNotificationTarget.none)
                Icon(Icons.chevron_left_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationStyle _styleFor(
    VisitorNotificationType type,
    ColorScheme scheme,
  ) =>
      switch (type) {
        VisitorNotificationType.appUpdate => _NotificationStyle(
            Icons.system_update_alt_rounded,
            scheme.primary,
            scheme.primaryContainer),
        VisitorNotificationType.place => const _NotificationStyle(
            Icons.place_rounded, Color(0xFFB57B2A), Color(0xFFFFF4E2)),
        VisitorNotificationType.event => const _NotificationStyle(
            Icons.event_available_rounded,
            Color(0xFF2563EB),
            Color(0xFFEFF6FF)),
        VisitorNotificationType.safety => const _NotificationStyle(
            Icons.warning_amber_rounded, Color(0xFFDC2626), Color(0xFFFEF2F2)),
        VisitorNotificationType.announcement => const _NotificationStyle(
            Icons.campaign_rounded, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
      };

  String _relativeTime(DateTime value) {
    final delta = DateTime.now().difference(value.toLocal());
    if (delta.inMinutes < 1) return 'الآن';
    if (delta.inMinutes < 60) return 'منذ ${delta.inMinutes} د';
    if (delta.inHours < 24) return 'منذ ${delta.inHours} س';
    if (delta.inDays < 7) return 'منذ ${delta.inDays} يوم';
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _NotificationStyle {
  const _NotificationStyle(this.icon, this.color, this.background);

  final IconData icon;
  final Color color;
  final Color background;
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد إشعارات حالياً',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'ستظهر هنا تحديثات وادنا والمعالم الجديدة والإعلانات المهمة.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
