import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';
class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({
    http.Client? client,
    String baseUrl = 'https://router.project-osrm.org/route/v1',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');
  final http.Client _client;
  final String _baseUrl;
  @override
  Future<RoutingResult> calculateRoute({
    required int placeId,
    required RoutePoint origin,
    required RoutePoint destination,
    required TravelMode mode,
    bool alternatives = false,
  }) async {
    final coordinates = '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.parse('$_baseUrl/${_profileFor(mode)}/$coordinates').replace(
      queryParameters: {
        'steps': 'true',
        'geometries': 'geojson',
        'overview': 'full',
        'alternatives': alternatives.toString(),
      },
    );
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      final payload = _readPayload(response);
      final code = payload['code']?.toString();
      if (response.statusCode < 200 || response.statusCode >= 300 || code != 'Ok') {
        throw RoutingException(_messageForResponse(code, response.statusCode));
      }
      final rawRoutes = payload['routes'];
      if (rawRoutes is! List || rawRoutes.isEmpty) {
        throw const RoutingException('لم يتم العثور على طريق مناسب إلى هذه الوجهة.');
      }
      final routes = rawRoutes
          .whereType<Map>()
          .map((route) => _parseRoute(Map<String, dynamic>.from(route)))
          .where((route) => route.geometry.length >= 2)
          .toList(growable: false);
      if (routes.isEmpty) {
        throw const RoutingException('لم يتم العثور على طريق مناسب إلى هذه الوجهة.');
      }
      return RoutingResult(origin: origin, destination: destination, routes: routes);
    } on RoutingException {
      rethrow;
    } on TimeoutException {
      throw const RoutingException('انتهت مهلة الاتصال بخدمة الملاحة.');
    } catch (_) {
      throw const RoutingException('تعذر حساب المسار حالياً. تحقق من الاتصال ثم أعد المحاولة.');
    }
  }
  Map<String, dynamic> _readPayload(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const RoutingException('استجابة خدمة الملاحة غير صالحة.');
    }
    if (decoded is! Map) {
      throw const RoutingException('استجابة خدمة الملاحة غير صالحة.');
    }
    return Map<String, dynamic>.from(decoded);
  }
  RouteOption _parseRoute(Map<String, dynamic> raw) {
    final geometry = _parseLineGeometry(raw['geometry']);
    final steps = _parseSteps(raw['legs'], geometry);
    return RouteOption(
      distanceMeters: (raw['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (raw['duration'] as num?)?.toDouble() ?? 0,
      geometry: geometry,
      steps: steps,
    );
  }
  List<LatLng> _parseLineGeometry(Object? raw) {
    if (raw is! Map || raw['coordinates'] is! List) return const [];
    return (raw['coordinates'] as List)
        .whereType<List>()
        .map((coordinate) {
          if (coordinate.length < 2) return null;
          final longitude = (coordinate[0] as num?)?.toDouble();
          final latitude = (coordinate[1] as num?)?.toDouble();
          if (latitude == null || longitude == null) return null;
          return LatLng(latitude, longitude);
        })
        .whereType<LatLng>()
        .toList(growable: false);
  }
  List<RouteStep> _parseSteps(Object? rawLegs, List<LatLng> routeGeometry) {
    if (rawLegs is! List) return const [];
    final steps = <RouteStep>[];
    var geometryCursor = 0;
    for (final rawLeg in rawLegs.whereType<Map>()) {
      final rawSteps = rawLeg['steps'];
      if (rawSteps is! List) continue;
      for (final rawStep in rawSteps.whereType<Map>()) {
        final step = Map<String, dynamic>.from(rawStep);
        final endpoint = _stepEndpoint(step['geometry']);
        final endGeometryIndex = endpoint == null
            ? geometryCursor
            : _closestGeometryIndex(routeGeometry, endpoint, geometryCursor);
        geometryCursor = endGeometryIndex;
        final rawManeuver = step['maneuver'];
        final maneuver = rawManeuver is Map ? _maneuverFor(Map<String, dynamic>.from(rawManeuver)) : 'continue';
        final streetName = step['name']?.toString().trim();
        steps.add(
          RouteStep(
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
            maneuver: maneuver,
            endGeometryIndex: endGeometryIndex,
            streetName: streetName == null || streetName.isEmpty ? null : streetName,
          ),
        );
      }
    }
    return List.unmodifiable(steps);
  }
  LatLng? _stepEndpoint(Object? rawGeometry) {
    if (rawGeometry is! Map || rawGeometry['coordinates'] is! List) return null;
    final coordinates = rawGeometry['coordinates'] as List;
    if (coordinates.isEmpty || coordinates.last is! List) return null;
    final endpoint = coordinates.last as List;
    if (endpoint.length < 2) return null;
    final longitude = (endpoint[0] as num?)?.toDouble();
    final latitude = (endpoint[1] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }
  int _closestGeometryIndex(List<LatLng> points, LatLng target, int startIndex) {
    if (points.isEmpty) return 0;
    var closestIndex = startIndex.clamp(0, points.length - 1).toInt();
    var closestDistance = double.infinity;
    for (var index = closestIndex; index < points.length; index++) {
      final candidate = points[index];
      final latitudeDifference = candidate.latitude - target.latitude;
      final longitudeDifference = candidate.longitude - target.longitude;
      final squaredDistance = latitudeDifference * latitudeDifference + longitudeDifference * longitudeDifference;
      if (squaredDistance < closestDistance) {
        closestDistance = squaredDistance;
        closestIndex = index;
      }
    }
    return closestIndex;
  }
  String _maneuverFor(Map<String, dynamic> raw) {
    final type = raw['type']?.toString();
    final modifier = raw['modifier']?.toString();
    if (type == 'arrive') return 'arrive';
    if (type == 'roundabout' || type == 'rotary') return 'roundabout';
    if (modifier == 'uturn') return 'u_turn';
    return switch (modifier) {
      'left' => 'left',
      'right' => 'right',
      'slight left' => 'slight_left',
      'slight right' => 'slight_right',
      'sharp left' => 'sharp_left',
      'sharp right' => 'sharp_right',
      _ => 'continue',
    };
  }
  String _profileFor(TravelMode mode) => switch (mode) {
        TravelMode.car => 'driving',
        TravelMode.foot => 'walking',
        TravelMode.bike => 'cycling',
      };
  String _messageForResponse(String? code, int statusCode) {
    if (code == 'NoRoute' || code == 'NoSegment') {
      return 'لم يتم العثور على طريق مناسب إلى هذه الوجهة.';
    }
    if (statusCode == 429) {
      return 'طلبات الملاحة كثيرة حالياً. حاول بعد لحظات.';
    }
    return 'تعذر حساب المسار حالياً. تحقق من الاتصال ثم أعد المحاولة.';
  }
}
