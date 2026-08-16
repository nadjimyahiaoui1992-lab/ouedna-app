import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../localization/ouedna_localization.dart';
import '../../features/notifications/data/ouedna_notification_service.dart';
import '../location/location_service.dart';

class EntryPermissionsDialog extends StatefulWidget {
  const EntryPermissionsDialog({
    super.key,
    required this.languageController,
  });

  final AppLanguageController languageController;

  @override
  State<EntryPermissionsDialog> createState() => _EntryPermissionsDialogState();
}

class _EntryPermissionsDialogState extends State<EntryPermissionsDialog> {
  final _locationService = LocationService();
  bool? _notificationsEnabled;
  bool? _locationEnabled;
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final notificationSettings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final notificationEnabled = notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.provisional;
      final locationEnabled = await Geolocator.isLocationServiceEnabled() &&
          await _hasLocationPermission();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = notificationEnabled;
        _locationEnabled = locationEnabled;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
          _locationEnabled = false;
          _loading = false;
        });
      }
    }
  }

  Future<bool> _hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _requestAccess() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final notificationGranted = await OuednaNotificationService.instance
        .requestPermission(widget.languageController);
    await _locationService.requestForEntry();
    await _refreshStatus();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationGranted;
      _requesting = false;
    });
    if (_notificationsEnabled == true && _locationEnabled == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.verified_user_outlined, size: 38),
        title: const Text('فعّل أدوات رحلتك'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'حتى يعمل «خطط رحلتي» والملاحة والتنبيهات بشكل احترافي، اسمح للتطبيق بالإشعارات والموقع عند الحاجة.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _PermissionRow(
                icon: Icons.notifications_active_outlined,
                title: 'الإشعارات',
                subtitle: 'تنبيهات التحديثات والمعلومات المهمة.',
                enabled: _notificationsEnabled,
              ),
              const SizedBox(height: 10),
              _PermissionRow(
                icon: Icons.my_location_rounded,
                title: 'الموقع وGPS',
                subtitle: 'حساب المسافة، نقطة البداية، والاتجاهات.',
                enabled: _locationEnabled,
              ),
              if (!_loading &&
                  (_notificationsEnabled != true || _locationEnabled != true))
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'يمكنك المتابعة دون الموافقة، ثم تفعيلهما لاحقًا من إعدادات الهاتف.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _requesting ? null : () => Navigator.pop(context),
            child: const Text('ليس الآن'),
          ),
          FilledButton.icon(
            onPressed: _requesting ? null : _requestAccess,
            icon: _requesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_open_rounded),
            label: const Text('تفعيل الآن'),
          ),
        ],
      );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled == true;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: enabled == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isEnabled
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isEnabled ? Colors.green : Colors.orange,
              ),
      ),
    );
  }
}
