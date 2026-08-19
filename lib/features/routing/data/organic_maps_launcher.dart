import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../places/domain/entities/place.dart';

enum OrganicMapsLaunchResult {
  launched,
  unavailable,
  invalidDestination,
  failed,
}

/// Opens Organic Maps through its documented Android deep-link API.
///
/// This is intentionally an optional fallback. Ouedna's internal navigation
/// remains the primary experience when Organic Maps is not installed.
class OrganicMapsLauncher {
  const OrganicMapsLauncher._();

  static Uri buildNavigationUri({
    required double latitude,
    required double longitude,
    required String destinationName,
    String mode = 'drive',
  }) {
    return Uri(
      scheme: 'om',
      host: 'v2',
      path: '/nav',
      queryParameters: {
        'origin': 'currentLocation',
        'destination': '$latitude,$longitude',
        'destination_name': destinationName,
        'mode': mode,
      },
    );
  }

  static Uri get downloadUri => Uri.parse('https://omaps.app/get?api');

  static Future<OrganicMapsLaunchResult> launchToPlace(Place place) async {
    if (!place.hasCoordinates ||
        place.latitude == null ||
        place.longitude == null) {
      return OrganicMapsLaunchResult.invalidDestination;
    }

    final uri = buildNavigationUri(
      latitude: place.latitude!,
      longitude: place.longitude!,
      destinationName: place.name,
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) return OrganicMapsLaunchResult.unavailable;

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched
          ? OrganicMapsLaunchResult.launched
          : OrganicMapsLaunchResult.failed;
    } catch (error, stackTrace) {
      debugPrint('Organic Maps launch failed: $error\n$stackTrace');
      return OrganicMapsLaunchResult.failed;
    }
  }

  static Future<bool> openDownloadPage() => launchUrl(
        downloadUri,
        mode: LaunchMode.externalApplication,
      );
}
