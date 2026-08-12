import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:souf_tour/features/routing/data/osrm_routing_service.dart';
import 'package:souf_tour/features/routing/domain/routing_models.dart';

void main() {
  test('builds an OSRM route request and parses route geometry and steps',
      () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'code': 'Ok',
          'routes': [
            {
              'distance': 1250.5,
              'duration': 180.0,
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [6.867, 33.367],
                  [6.872, 33.371],
                  [6.88, 33.38],
                ],
              },
              'legs': [
                {
                  'steps': [
                    {
                      'distance': 250.0,
                      'duration': 40.0,
                      'name': 'شارع الأمير عبد القادر',
                      'geometry': {
                        'type': 'LineString',
                        'coordinates': [
                          [6.867, 33.367],
                          [6.872, 33.371],
                        ],
                      },
                      'maneuver': {'type': 'turn', 'modifier': 'right'},
                    },
                    {
                      'distance': 0.0,
                      'duration': 0.0,
                      'name': '',
                      'geometry': {
                        'type': 'LineString',
                        'coordinates': [
                          [6.872, 33.371],
                          [6.88, 33.38],
                        ],
                      },
                      'maneuver': {'type': 'arrive'},
                    },
                  ],
                },
              ],
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = OsrmRoutingService(
      client: client,
      baseUrl: 'https://router.example.test/route/v1',
    );

    final result = await service.calculateRoute(
      placeId: 42,
      origin: const RoutePoint(latitude: 33.367, longitude: 6.867),
      destination: const RoutePoint(latitude: 33.38, longitude: 6.88),
      mode: TravelMode.car,
      alternatives: true,
    );

    expect(requestedUri.path, '/route/v1/driving/6.867,33.367;6.88,33.38');
    expect(requestedUri.queryParameters['steps'], 'true');
    expect(requestedUri.queryParameters['alternatives'], 'true');
    expect(result.routes, hasLength(1));
    expect(result.routes.single.distanceMeters, 1250.5);
    expect(result.routes.single.durationSeconds, 180.0);
    expect(result.routes.single.geometry, hasLength(3));
    expect(result.routes.single.steps.first.maneuver, 'right');
    expect(
        result.routes.single.steps.first.streetName, 'شارع الأمير عبد القادر');
    expect(result.routes.single.steps.last.maneuver, 'arrive');
    expect(result.routes.single.steps.last.endGeometryIndex, 2);
  });
}
