import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled)
      throw const LocationException('خدمة تحديد الموقع غير مفعلة على الجهاز.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('لم يتم منح إذن الوصول إلى الموقع.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'تم رفض إذن الموقع بشكل دائم. فعّله من إعدادات الهاتف.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
