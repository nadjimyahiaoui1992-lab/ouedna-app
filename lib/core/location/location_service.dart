import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationIssue {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  unavailable,
}

class LocationService {
  /// Acquires a location only after a visitor explicitly uses a location feature.
  Future<Position> getCurrentPosition() async {
    await _ensureLocationAccess();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        'استغرق تحديد موقعك وقتاً أطول من المتوقع. انتقل إلى مكان مفتوح ثم أعد المحاولة.',
        issue: LocationIssue.timedOut,
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'خدمة تحديد الموقع غير مفعلة على الجهاز.',
        issue: LocationIssue.serviceDisabled,
      );
    } on PermissionDeniedException {
      throw const LocationException(
        'لم يتم منح إذن الوصول إلى الموقع.',
        issue: LocationIssue.permissionDenied,
      );
    }
  }

  /// Starts only after a visitor explicitly starts in-app navigation.
  /// No background permission or tracking is requested.
  Stream<Position> watchPosition() async* {
    await _ensureLocationAccess();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    );
  }

  Future<bool> openDeviceLocationSettings() =>
      Geolocator.openLocationSettings();

  Future<bool> openApplicationSettings() => Geolocator.openAppSettings();

  Future<void> _ensureLocationAccess() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'خدمة تحديد الموقع غير مفعلة على الجهاز.',
        issue: LocationIssue.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'لم يتم منح إذن الوصول إلى الموقع.',
        issue: LocationIssue.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'تم رفض إذن الموقع بشكل دائم. فعّله من إعدادات الهاتف.',
        issue: LocationIssue.permissionDeniedForever,
      );
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.message,
      {this.issue = LocationIssue.unavailable});

  final String message;
  final LocationIssue issue;

  String? get recoveryLabel => switch (issue) {
        LocationIssue.serviceDisabled => 'فتح إعدادات الموقع',
        LocationIssue.permissionDeniedForever => 'فتح إعدادات التطبيق',
        _ => null,
      };

  @override
  String toString() => message;
}
