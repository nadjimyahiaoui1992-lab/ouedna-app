import 'package:flutter/material.dart';

import '../data/app_update_service.dart';

class UpdateCenterPage extends StatefulWidget {
  const UpdateCenterPage({super.key});

  @override
  State<UpdateCenterPage> createState() => _UpdateCenterPageState();
}

class _UpdateCenterPageState extends State<UpdateCenterPage> {
  final _service = AppUpdateService();
  AppUpdateInfo? _update;
  String? _error;
  String? _localApkPath;
  double? _downloadProgress;
  bool _loading = true;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
      _localApkPath = null;
      _downloadProgress = null;
    });
    try {
      final update = await _service.checkForUpdate();
      if (mounted) setState(() => _update = update);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'تعذر الاتصال بخدمة التحديث. تحقق من الإنترنت ثم أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final update = _update;
    if (update == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _downloadProgress = 0;
    });
    try {
      final path = await _service.downloadVerifiedApk(update, (progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      });
      if (mounted) setState(() => _localApkPath = path);
    } on AppUpdateException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'فشل تنزيل التحديث. حاول مجدداً لاحقاً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _install() async {
    final path = _localApkPath;
    if (path == null || _installing) return;
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      await _service.installApk(context, path);
    } on AppUpdateException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر بدء تثبيت التحديث.');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Future<void> _openStore() async {
    final update = _update;
    if (update == null) return;
    try {
      await _service.openStore(update);
    } on AppUpdateException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final update = _update;
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.system_update_alt_rounded, size: 50),
                  const SizedBox(height: 12),
                  Text('تحديثات وادنا',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    AppUpdateService.isDirectDistribution
                        ? 'يتم التحقق من بصمة ملف التحديث قبل فتح مثبت أندرويد.'
                        : 'يتم التحديث من خلال قناة التوزيع الرسمية للتطبيق.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator()))
          else if (_error != null)
            _StatusCard(
                icon: Icons.error_outline_rounded,
                message: _error!,
                color: scheme.error,
                actionLabel: 'إعادة التحقق',
                onAction: _check)
          else if (update == null)
            _StatusCard(
                icon: Icons.cloud_off_outlined,
                message: 'لا تتوفر معلومات تحديث حالياً.',
                color: scheme.onSurfaceVariant,
                actionLabel: 'إعادة التحقق',
                onAction: _check)
          else if (!update.isUpdateAvailable)
            _StatusCard(
                icon: Icons.verified_outlined,
                message:
                    'تطبيقك محدّث. الإصدار الحالي: ${update.currentVersion}',
                color: Colors.teal,
                actionLabel: 'تحقق مجدداً',
                onAction: _check)
          else ...[
            _VersionCard(update: update),
            const SizedBox(height: 16),
            if (AppUpdateService.isDirectDistribution) ...[
              if (_localApkPath == null)
                FilledButton.icon(
                  onPressed: update.hasVerifiedDirectPackage ? _download : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('تنزيل التحديث الموثّق'),
                )
              else
                FilledButton.icon(
                  onPressed: _installing ? null : _install,
                  icon: _installing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.install_mobile_outlined),
                  label: const Text('تثبيت التحديث الآن'),
                ),
              if (_downloadProgress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 6),
                Text('تنزيل: ${(_downloadProgress! * 100).round()}%',
                    textAlign: TextAlign.center),
              ],
              if (!update.hasVerifiedDirectPackage) ...[
                const SizedBox(height: 12),
                const Text(
                    'سيصبح التنزيل متاحاً عند إعداد رابط APK آمن وبصمة SHA-256 في لوحة الإدارة.',
                    textAlign: TextAlign.center),
              ],
            ] else
              FilledButton.icon(
                onPressed: update.storeUrl == null ? null : _openStore,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('فتح صفحة التحديث الرسمية'),
              ),
          ],
          const SizedBox(height: 18),
          const Text(
            'لن يتم تثبيت أي تحديث بصمت. يفتح التطبيق واجهة التثبيت الأصلية في أندرويد بعد تأكيدك، ويحميك من الملفات المعدّلة عبر مطابقة بصمة SHA-256.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.update});
  final AppUpdateInfo update;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.new_releases_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('يتوفر الإصدار ${update.latestVersion}',
                          style: const TextStyle(fontWeight: FontWeight.w900))),
                  if (update.forceUpdate) const Chip(label: Text('مهم')),
                ],
              ),
              const SizedBox(height: 10),
              Text(update.releaseNotes?.isNotEmpty == true
                  ? update.releaseNotes!
                  : 'يتضمن هذا الإصدار تحسينات في الأداء والأمان وتجربة الاستخدام.'),
            ],
          ),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.icon,
      required this.message,
      required this.color,
      required this.actionLabel,
      required this.onAction});
  final IconData icon;
  final String message;
  final Color color;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon, size: 42, color: color),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, height: 1.45)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}
