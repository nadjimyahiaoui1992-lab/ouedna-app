import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    await _ensureLocationAccess();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
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

    yield* Geolocator.getPositionStream(locationSettings: settings);
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
