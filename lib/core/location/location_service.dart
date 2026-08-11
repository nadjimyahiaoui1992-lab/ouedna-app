import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    await _ensureLocationAccess();
    return Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }

  /// Starts only after a visitor has explicitly chosen an action requiring GPS.
  /// It never runs on application launch or while merely browsing the catalogue.
  Stream<Position> watchPosition() async* {
    await _ensureLocationAccess();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    );
  }

  Future<void> _ensureLocationAccess() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException('خدمة تحديد الموقع غير مفعلة على الجهاز.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('لم يتم منح إذن الوصول إلى الموقع.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'تم رفض إذن الموقع بشكل دائم. فعّله من إعدادات الهاتف.',
      );
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
