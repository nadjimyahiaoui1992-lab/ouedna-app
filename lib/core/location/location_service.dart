import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  static const _maximumInitialAccuracyMeters = 120.0;

  /// يحصل على قراءة GPS حديثة. لا نستعمل آخر موقع مخزن للجهاز لأن ذلك قد
  /// ينتج مسافات بعيدة وغير واقعية عند بدء رحلة جديدة.
  Future<bool> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<bool> requestForEntry() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return false;
    }
    final allowed = await requestPermission();
    if (!allowed) await Geolocator.openAppSettings();
    return allowed;
  }

  Future<Position> getCurrentPosition() async {
    await _ensureLocationAccess();
    try {
      final settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 2),
      );
      final position = await Geolocator.getPositionStream(
        locationSettings: settings,
      )
          .where((item) =>
              item.accuracy >= 0 &&
              item.accuracy <= _maximumInitialAccuracyMeters)
          .first
          .timeout(const Duration(seconds: 20));
      return position;
    } on TimeoutException {
      throw const LocationException(
        'تعذر الحصول على موقع GPS دقيق. انتظر في مكان مفتوح وتحقق من تشغيل الموقع.',
      );
    } catch (error) {
      throw LocationException('تعذر تحديد موقعك حالياً: $error');
    }
  }

  /// Flux GPS مخصص لصفحة الملاحة فقط. يظهر إشعار نظام شفاف أثناء
  /// تشغيل الملاحة حتى لا يوقف Android التتبع عند الانتقال المؤقت للخلفية.
  Stream<Position> watchNavigationPosition() async* {
    await _ensureLocationAccess();
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 6,
      intervalDuration: const Duration(seconds: 3),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'ملاحة وادنا نشطة',
        notificationText: 'يتم تحديث موقعك ومسارك أثناء الرحلة.',
        notificationChannelName: 'الملاحة الحية',
        setOngoing: true,
      ),
    );

    yield* Geolocator.getPositionStream(locationSettings: settings).where(
      (position) => position.accuracy >= 0 && position.accuracy <= 180,
    );
  }

  Future<Position?> tryGetCurrentPosition() async {
    try {
      return await getCurrentPosition();
    } on LocationException {
      return null;
    }
  }

  Future<void> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'فعّل خدمة الموقع من إعدادات الهاتف ثم أعد المحاولة.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'لم يتم السماح للتطبيق بالوصول إلى موقعك.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.',
      );
    }
  }
}
