import 'package:flutter_test/flutter_test.dart';

import 'package:ouedna_app/features/compass/domain/itinerary_models.dart';
import 'package:ouedna_app/features/places/domain/entities/place.dart';
import 'package:ouedna_app/features/routing/data/organic_maps_launcher.dart';
import 'package:ouedna_app/features/routing/domain/routing_models.dart';

void main() {
  test('builds an Organic Maps navigation deep link', () {
    final uri = OrganicMapsLauncher.buildNavigationUri(
      latitude: 33.3683,
      longitude: 6.8674,
      destinationName: 'سوق الوادي',
      mode: TravelMode.foot,
    );

    expect(uri.scheme, 'om');
    expect(uri.host, 'v2');
    expect(uri.path, '/nav');
    expect(uri.queryParameters['origin'], 'currentLocation');
    expect(uri.queryParameters['destination'], '33.3683,6.8674');
    expect(uri.queryParameters['destination_name'], 'سوق الوادي');
    expect(uri.queryParameters['mode'], 'pedestrian');
    expect(
      uri.queryParameters['callback'],
      'ouedna-v2://organicmaps/route-complete',
    );
  });

  test('builds a multi-stop itinerary deep link', () {
    final itinerary = CompassItinerary(
      stops: [
        CompassStop(
          order: 1,
          place: const Place(
            id: 1,
            name: 'المحطة الأولى',
            latitude: 33.3683,
            longitude: 6.8674,
          ),
        ),
        CompassStop(
          order: 2,
          place: const Place(
            id: 2,
            name: 'المحطة الثانية',
            latitude: 33.3700,
            longitude: 6.8700,
          ),
        ),
        CompassStop(
          order: 3,
          place: const Place(
            id: 3,
            name: 'المحطة الأخيرة',
            latitude: 33.3720,
            longitude: 6.8750,
          ),
        ),
      ],
    );

    final uri = OrganicMapsLauncher.buildItineraryUri(
      itinerary: itinerary,
      mode: TravelMode.car,
    );

    expect(uri.queryParameters['destination'], '33.372,6.875');
    expect(uri.queryParameters['destination_name'], 'المحطة الأخيرة');
    expect(uri.queryParameters['waypoints'], '33.3683,6.8674|33.37,6.87');
    expect(
        uri.queryParameters['waypoint_names'], 'المحطة الأولى|المحطة الثانية');
    expect(uri.queryParameters['mode'], 'drive');
  });
}
