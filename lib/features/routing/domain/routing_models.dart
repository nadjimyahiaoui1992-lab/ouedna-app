import 'package:latlong2/latlong.dart';

enum TravelMode { car, foot, motorcycle }

extension TravelModeExt on TravelMode {
  String get label => switch (this) {
        TravelMode.car => 'سيارة',
        TravelMode.foot => 'مشياً',
        TravelMode.motorcycle => 'دراجة نارية',
      };
  String get apiProfile => switch (this) {
        TravelMode.car => 'driving',
        TravelMode.foot => 'walking',
        TravelMode.motorcycle => 'driving',
      };
}

class RoutePoint {
  const RoutePoint({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
}

class RouteStep {
  const RouteStep({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
    required this.endGeometryIndex,
    this.streetName,
  });
  final double distanceMeters;
  final double durationSeconds;
  final String maneuver;
  final int endGeometryIndex;
  final String? streetName;
}

class RouteOption {
  const RouteOption({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    required this.steps,
  });
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometry;
  final List<RouteStep> steps;
}

class RoutingResult {
  const RoutingResult({
    required this.origin,
    required this.destination,
    required this.routes,
  });
  final RoutePoint origin;
  final RoutePoint destination;
  final List<RouteOption> routes;
}

class RoutingException implements Exception {
  const RoutingException(this.message, {this.isConfigurationError = false});
  final String message;
  final bool isConfigurationError;
  @override
  String toString() => message;
}
