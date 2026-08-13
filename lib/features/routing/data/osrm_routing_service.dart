import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../domain/routing_models.dart';
import '../domain/routing_service.dart';

class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({
    http.Client? client,
    String? baseUrl,
    String? customBaseUrl,
  })  : _client = client ?? http.Client(),
        _customBaseUrl =
            (customBaseUrl ?? baseUrl)?.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String? _customBaseUrl;

  static const _publicCarBase = 'https://routing.openstreetmap.de/routed-car';
  static const _publicFootBase = 'https://routing.openstreetmap.de/routed-foot';
  static const _legacyPublicBase = 'https://router.project-osrm.org';

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
    RoutingException? lastError;

    for (final endpoint in _endpointsFor(mode)) {
      final routeBase = endpoint.baseUrl.endsWith('/route/v1')
          ? endpoint.baseUrl
          : '${endpoint.baseUrl}/route/v1';
      final uri =
          Uri.parse('$routeBase/${endpoint.profile}/$coordinates').replace(
        queryParameters: {
          'steps': 'true',
          'geometries': 'geojson',
          'overview': 'full',
          'alternatives': alternatives.toString(),
        },
      );

      try {
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 12));
        final payload = _readPayload(response);
        final code = payload['code']?.toString();
        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            code != 'Ok') {
          lastError = RoutingException(
            _messageForResponse(code, response.statusCode, mode),
          );
          continue;
        }

        final rawRoutes = payload['routes'];
        if (rawRoutes is! List || rawRoutes.isEmpty) {
          lastError = const RoutingException(
            'لم يتم العثور على طريق مناسب إلى هذه الوجهة.',
          );
          continue;
        }

        final routes = rawRoutes
            .whereType<Map>()
            .map((route) => _parseRoute(Map<String, dynamic>.from(route), mode))
            .where((route) => route.geometry.length >= 2)
            .toList(growable: false);
        if (routes.isNotEmpty) {
          return RoutingResult(
            origin: origin,
            destination: destination,
            routes: routes,
          );
        }
      } on TimeoutException {
        lastError = const RoutingException('انتهت مهلة الاتصال بخدمة الملاحة.');
      } on RoutingException catch (error) {
        lastError = error;
      } catch (_) {
        lastError = const RoutingException(
          'تعذر الاتصال بخدمة الملاحة حالياً.',
        );
      }
    }

    throw lastError ?? const RoutingException('تعذر حساب المسار حالياً.');
  }

  List<_RoutingEndpoint> _endpointsFor(TravelMode mode) {
    final customBaseUrl = _customBaseUrl;
    final custom = customBaseUrl == null
        ? const <_RoutingEndpoint>[]
        : [
            _RoutingEndpoint(
              customBaseUrl,
              switch (mode) {
                TravelMode.foot => 'walking',
                TravelMode.car || TravelMode.motorcycle => 'driving',
              },
            ),
          ];
    final public = switch (mode) {
      TravelMode.foot => const [
          _RoutingEndpoint(_publicFootBase, 'foot'),
        ],
      TravelMode.car => const [
          _RoutingEndpoint(_publicCarBase, 'driving'),
          _RoutingEndpoint(_legacyPublicBase, 'driving'),
        ],
      // لا يوجد ملف OSRM عام مخصص للدراجات النارية؛ نستعمل شبكة الطرق
      // الخاصة بالسيارات ثم نضبط زمن الوصول بصورة محافظة للموتوسيكل.
      TravelMode.motorcycle => const [
          _RoutingEndpoint(_publicCarBase, 'driving'),
          _RoutingEndpoint(_legacyPublicBase, 'driving'),
        ],
    };
    return [...custom, ...public];
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

  RouteOption _parseRoute(Map<String, dynamic> raw, TravelMode mode) {
    final geometry = _parseLineGeometry(raw['geometry']);
    final steps = _parseSteps(raw['legs'], geometry);
    final originalDuration = (raw['duration'] as num?)?.toDouble() ?? 0;
    return RouteOption(
      distanceMeters: (raw['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: _durationForMode(originalDuration, mode),
      geometry: geometry,
      steps: steps,
    );
  }

  double _durationForMode(double durationSeconds, TravelMode mode) {
    return switch (mode) {
      TravelMode.car || TravelMode.foot => durationSeconds,
      // تقدير محافظ: أقرب من السيارة في الازدحام ولكن ليس زمنًا غير واقعي.
      TravelMode.motorcycle => durationSeconds * 0.88,
    };
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
        final maneuver = rawManeuver is Map
            ? _maneuverFor(Map<String, dynamic>.from(rawManeuver))
            : 'continue';
        final streetName = step['name']?.toString().trim();
        steps.add(
          RouteStep(
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
            maneuver: maneuver,
            endGeometryIndex: endGeometryIndex,
            streetName:
                streetName == null || streetName.isEmpty ? null : streetName,
          ),
        );
      }
    }
    return List.unmodifiable(steps);
  }

  LatLng? _stepEndpoint(Object? rawGeometry) {
    if (rawGeometry is! Map || rawGeometry['coordinates'] is! List) {
      return null;
    }
    final coordinates = rawGeometry['coordinates'] as List;
    if (coordinates.isEmpty || coordinates.last is! List) return null;
    final endpoint = coordinates.last as List;
    if (endpoint.length < 2) return null;
    final longitude = (endpoint[0] as num?)?.toDouble();
    final latitude = (endpoint[1] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  int _closestGeometryIndex(
      List<LatLng> points, LatLng target, int startIndex) {
    if (points.isEmpty) return 0;
    var closestIndex = startIndex.clamp(0, points.length - 1).toInt();
    var closestDistance = double.infinity;
    for (var index = closestIndex; index < points.length; index++) {
      final candidate = points[index];
      final latitudeDifference = candidate.latitude - target.latitude;
      final longitudeDifference = candidate.longitude - target.longitude;
      final squaredDistance = latitudeDifference * latitudeDifference +
          longitudeDifference * longitudeDifference;
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

  String _messageForResponse(
    String? code,
    int statusCode,
    TravelMode mode,
  ) {
    if (code == 'NoRoute' || code == 'NoSegment') {
      return mode == TravelMode.foot
          ? 'لم يتم العثور على مسار مشي آمن إلى هذه الوجهة.'
          : 'لم يتم العثور على طريق مناسب إلى هذه الوجهة.';
    }
    if (statusCode == 429) {
      return 'طلبات الملاحة كثيرة حالياً. حاول بعد لحظات.';
    }
    return 'تعذر حساب المسار حالياً. تحقق من الاتصال ثم أعد المحاولة.';
  }
}

class _RoutingEndpoint {
  const _RoutingEndpoint(this.baseUrl, this.profile);

  final String baseUrl;
  final String profile;
}
