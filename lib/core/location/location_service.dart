import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('فعّل خدمة الموقع من إعدادات الهاتف ثم أعد المحاولة.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('لم يتم السماح للتطبيق بالوصول إلى موقعك.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (error) {
      throw LocationException('تعذر تحديد موقعك حالياً: $error');
    }
  }

  Future<Position?> tryGetCurrentPosition() async {
    try {
      return await getCurrentPosition();
    } on LocationException {
      return null;
    }
  }
}
