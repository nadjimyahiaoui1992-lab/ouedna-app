import 'package:flutter_test/flutter_test.dart';

import 'package:ouedna_app/features/routing/data/organic_maps_launcher.dart';

void main() {
  test('builds an Organic Maps navigation deep link', () {
    final uri = OrganicMapsLauncher.buildNavigationUri(
      latitude: 33.3683,
      longitude: 6.8674,
      destinationName: 'سوق الوادي',
    );

    expect(uri.scheme, 'om');
    expect(uri.host, 'v2');
    expect(uri.path, '/nav');
    expect(uri.queryParameters['origin'], 'currentLocation');
    expect(uri.queryParameters['destination'], '33.3683,6.8674');
    expect(uri.queryParameters['destination_name'], 'سوق الوادي');
    expect(uri.queryParameters['mode'], 'drive');
  });
}
