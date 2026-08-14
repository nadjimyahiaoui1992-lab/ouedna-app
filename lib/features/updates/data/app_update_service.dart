import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.storeUrl,
    required this.directApkUrl,
    required this.apkSha256,
    required this.releaseNotes,
    required this.currentVersion,
  });

  final String latestVersion;
  final bool forceUpdate;
  final String? storeUrl;
  final String? directApkUrl;
  final String? apkSha256;
  final String? releaseNotes;
  final String currentVersion;

  bool get isUpdateAvailable =>
      _compareVersions(latestVersion, currentVersion) > 0;
  bool get hasVerifiedDirectPackage =>
      directApkUrl != null &&
      directApkUrl!.startsWith('https://') &&
      apkSha256 != null &&
      RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(apkSha256!);

  static int _compareVersions(String first, String second) {
    final firstParts = first
        .split('+')
        .first
        .split('.')
        .map((value) => int.tryParse(value) ?? 0)
        .toList();
    final secondParts = second
        .split('+')
        .first
        .split('.')
        .map((value) => int.tryParse(value) ?? 0)
        .toList();
    final length = firstParts.length > secondParts.length
        ? firstParts.length
        : secondParts.length;
    for (var index = 0; index < length; index++) {
      final left = index < firstParts.length ? firstParts[index] : 0;
      final right = index < secondParts.length ? secondParts[index] : 0;
      if (left != right) return left.compareTo(right);
    }
    return 0;
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppUpdateService {
  AppUpdateService({SupabaseClient? client, http.Client? httpClient})
      : _client = client,
        _httpClient = httpClient ?? http.Client();

  static const bool isDirectDistribution =
      bool.fromEnvironment('OUEDNA_DIRECT_BUILD', defaultValue: false);

  final SupabaseClient? _client;
  final http.Client _httpClient;

  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final client = _client ?? Supabase.instance.client;
    final row = await client
        .from('app_config')
        .select(
            'latest_version, force_update, android_store_url, direct_apk_url, apk_sha256, release_notes')
        .eq('id', 1)
        .maybeSingle();
    if (row == null || row['latest_version'] == null) return null;
    return AppUpdateInfo(
      latestVersion: row['latest_version'].toString().trim(),
      forceUpdate: row['force_update'] == true,
      storeUrl: _safeHttps(row['android_store_url']),
      directApkUrl: _safeHttps(row['direct_apk_url']),
      apkSha256: row['apk_sha256']?.toString().trim(),
      releaseNotes: row['release_notes']?.toString().trim(),
      currentVersion: packageInfo.version,
    );
  }

  Future<String> downloadVerifiedApk(
      AppUpdateInfo update, ValueChanged<double>? onProgress) async {
    if (!isDirectDistribution) {
      throw const AppUpdateException(
          'التثبيت المباشر غير متاح في إصدار متجر Play.');
    }
    if (!update.hasVerifiedDirectPackage) {
      throw const AppUpdateException(
          'ملف التحديث أو بصمته غير مكتملين في إعدادات الإصدار.');
    }

    final response = await _httpClient
        .send(http.Request('GET', Uri.parse(update.directApkUrl!)));
    if (response.statusCode != HttpStatus.ok) {
      throw const AppUpdateException('تعذر تنزيل ملف التحديث من الخادم.');
    }
    final expectedLength = response.contentLength;
    if (expectedLength != null && expectedLength > 250 * 1024 * 1024) {
      throw const AppUpdateException('ملف التحديث أكبر من الحد المسموح به.');
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ouedna-${update.latestVersion}.apk');
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > 250 * 1024 * 1024) {
          throw const AppUpdateException(
              'توقف التنزيل لأن الملف تجاوز الحد المسموح به.');
        }
        sink.add(chunk);
        if (expectedLength != null && expectedLength > 0) {
          onProgress?.call(received / expectedLength);
        }
      }
    } finally {
      await sink.close();
    }

    if (!await file.exists() || await file.length() == 0) {
      throw const AppUpdateException('تعذر حفظ ملف التحديث على الجهاز.');
    }
    final actualHash = sha256.convert(await file.readAsBytes()).toString();
    if (actualHash.toLowerCase() != update.apkSha256!.toLowerCase()) {
      try {
        await file.delete();
      } catch (_) {
        // The invalid update remains inaccessible and will be replaced on the next download.
      }
      throw const AppUpdateException(
          'فشل التحقق من سلامة ملف التحديث؛ تم إلغاء التثبيت لحمايتك.');
    }
    onProgress?.call(1);
    return file.path;
  }

  Future<void> installApk(BuildContext context, String apkFilePath) async {
    if (!Platform.isAndroid) {
      throw const AppUpdateException('تثبيت APK متاح على أجهزة أندرويد فقط.');
    }
    final file = File(apkFilePath);
    if (!await file.exists() || !apkFilePath.toLowerCase().endsWith('.apk')) {
      throw const AppUpdateException(
          'مسار ملف APK غير صالح أو أن الملف غير موجود.');
    }

    var permission = await Permission.requestInstallPackages.status;
    if (!permission.isGranted) {
      if (!context.mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.security_update_good_outlined, size: 38),
          title: const Text('السماح بتثبيت التحديث'),
          content: const Text(
            'سيفتح أندرويد إعداداً خاصاً بهذا التطبيق للسماح بتثبيت تحديث وادنا الذي تم التحقق من سلامته. لا تمنح هذه الصلاحية لأي تطبيق أو ملف غير موثوق.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ليس الآن'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      );
      if (accepted != true) {
        throw const AppUpdateException('لم يتم منح الإذن لتثبيت التحديث.');
      }
      permission = await Permission.requestInstallPackages.request();
      if (!permission.isGranted) {
        throw const AppUpdateException(
            'لا يزال الإذن غير مفعّل. فعّله من شاشة «السماح من هذا المصدر» ثم أعد المحاولة.');
      }
    }

    final result = await OpenFilex.open(
      apkFilePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw AppUpdateException('تعذر فتح مثبّت أندرويد: ${result.message}');
    }
  }

  Future<void> openStore(AppUpdateInfo update) async {
    final url = update.storeUrl;
    if (url == null) {
      throw const AppUpdateException('رابط المتجر غير مهيأ بعد.');
    }
    final opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened)
      throw const AppUpdateException('تعذر فتح صفحة التحديث في المتجر.');
  }

  void dispose() => _httpClient.close();

  String? _safeHttps(dynamic value) {
    final candidate = value?.toString().trim();
    if (candidate == null || candidate.isEmpty) return null;
    final uri = Uri.tryParse(candidate);
    return uri != null && uri.scheme == 'https' ? candidate : null;
  }
}
