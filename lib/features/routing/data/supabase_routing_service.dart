import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/routing_models.dart';
import '../domain/routing_service.dart';

class SupabaseRoutingService implements RoutingService {
  SupabaseRoutingService(this._client);

  final SupabaseClient _client;

  @override
  Future<RoutingResult> calculateRoute({
    required int placeId,
    required RoutePoint origin,
    required TravelMode mode,
    bool alternatives = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'routing',
        body: {
          'place_id': placeId,
          'origin': origin.toJson(),
          'mode': mode.apiProfile,
          'alternatives': alternatives,
        },
      );
      final payload = response.data;
      if (payload is! Map) {
        throw const RoutingException('تعذر قراءة بيانات المسار.');
      }
      final error = payload['error']?.toString();
      if (error != null && error.isNotEmpty) {
        throw RoutingException(
          _messageForError(error),
          isConfigurationError: error == 'routing_not_configured',
        );
      }
      return _parseResult(Map<String, dynamic>.from(payload));
    } on RoutingException {
      rethrow;
    } on FunctionException catch (_) {
      throw const RoutingException('تعذر الاتصال بخدمة الملاحة حالياً.');
    } catch (_) {
      throw const RoutingException(
          'تعذر حساب المسار حالياً. تحقق من الاتصال ثم أعد المحاولة.');
    }
  }

  RoutingResult _parseResult(Map<String, dynamic> payload) {
    final origin = _parsePoint(payload['origin']);
    final destination = _parsePoint(payload['destination']);
    final rawRoutes = payload['routes'];
    if (rawRoutes is! List || rawRoutes.isEmpty) {
      throw const RoutingException('لا يوجد مسار متاح لهذه الوجهة.');
    }
    final routes = rawRoutes
        .whereType<Map>()
        .map((route) => _parseRoute(Map<String, dynamic>.from(route)))
        .where((route) => route.geometry.length >= 2)
        .toList(growable: false);
    if (routes.isEmpty)
      throw const RoutingException('لا يوجد مسار متاح لهذه الوجهة.');
    return RoutingResult(
        origin: origin, destination: destination, routes: routes);
  }

  RoutePoint _parsePoint(Object? raw) {
    if (raw is! Map)
      throw const RoutingException('تعذر قراءة إحداثيات المسار.');
    final latitude = (raw['lat'] as num?)?.toDouble();
    final longitude = (raw['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const RoutingException('تعذر قراءة إحداثيات المسار.');
    }
    return RoutePoint(latitude: latitude, longitude: longitude);
  }

  RouteOption _parseRoute(Map<String, dynamic> raw) {
    final rawGeometry = raw['geometry'];
    final geometry = rawGeometry is List
        ? rawGeometry
            .whereType<Map>()
            .map((point) {
              final latitude = (point['lat'] as num?)?.toDouble();
              final longitude = (point['lng'] as num?)?.toDouble();
              if (latitude == null || longitude == null) return null;
              return LatLng(latitude, longitude);
            })
            .whereType<LatLng>()
            .toList(growable: false)
        : const <LatLng>[];
    final rawSteps = raw['steps'];
    final steps = rawSteps is List
        ? rawSteps.whereType<Map>().map((step) {
            final value = Map<String, dynamic>.from(step);
            return RouteStep(
              distanceMeters:
                  (value['distance_meters'] as num?)?.toDouble() ?? 0,
              durationSeconds:
                  (value['duration_seconds'] as num?)?.toDouble() ?? 0,
              maneuver: value['maneuver']?.toString() ?? 'continue',
              endGeometryIndex:
                  (value['end_geometry_index'] as num?)?.toInt() ?? 0,
              streetName: value['street_name']?.toString(),
            );
          }).toList(growable: false)
        : const <RouteStep>[];
    return RouteOption(
      distanceMeters: (raw['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (raw['duration_seconds'] as num?)?.toDouble() ?? 0,
      geometry: geometry,
      steps: steps,
    );
  }

  String _messageForError(String error) => switch (error) {
        'routing_not_configured' => 'خدمة الملاحة قيد الإعداد. حاول لاحقاً.',
        'destination_unavailable' =>
          'الملاحة غير متاحة لأن هذا المكان لا يملك إحداثيات منشورة.',
        'no_route' => 'لم يتم العثور على طريق مناسب إلى هذه الوجهة.',
        'rate_limited' => 'تم تجاوز حد طلبات الملاحة مؤقتاً. حاول بعد قليل.',
        'unauthorized' =>
          'تعذر التحقق من جلسة الملاحة. أعد فتح التطبيق وحاول مرة أخرى.',
        _ => 'تعذر حساب المسار حالياً. تحقق من الاتصال ثم أعد المحاولة.',
      };
}
