import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../compass/domain/itinerary_models.dart';
import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';

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

  static const _lastDestinationKey = 'ouedna.organic_maps.last_destination';
  static const _callbackUri = 'ouedna-v2://organicmaps/route-complete';

  static Uri buildNavigationUri({
    required double latitude,
    required double longitude,
    required String destinationName,
    TravelMode mode = TravelMode.car,
  }) {
    return _buildRouteUri(
      stops: [
        _OrganicMapsStop(
          latitude: latitude,
          longitude: longitude,
          name: destinationName,
        ),
      ],
      mode: mode,
    );
  }

  static Uri buildItineraryUri({
    required CompassItinerary itinerary,
    TravelMode mode = TravelMode.car,
  }) {
    final stops = itinerary.stops
        .where((stop) => stop.place.hasCoordinates)
        .map(
          (stop) => _OrganicMapsStop(
            latitude: stop.place.latitude!,
            longitude: stop.place.longitude!,
            name: stop.place.name,
          ),
        )
        .toList(growable: false);
    return _buildRouteUri(stops: stops, mode: mode);
  }

  static Uri get downloadUri => Uri.parse('https://omaps.app/get?api');

  static Future<OrganicMapsLaunchResult> launchToPlace(
    Place place, {
    TravelMode mode = TravelMode.car,
  }) async {
    if (!place.hasCoordinates ||
        place.latitude == null ||
        place.longitude == null) {
      return OrganicMapsLaunchResult.invalidDestination;
    }

    return _launch(
      _buildRouteUri(
        stops: [
          _OrganicMapsStop(
            latitude: place.latitude!,
            longitude: place.longitude!,
            name: place.name,
          ),
        ],
        mode: mode,
      ),
      lastDestination: _LastDestination(
        name: place.name,
        latitude: place.latitude!,
        longitude: place.longitude!,
        mode: mode,
      ),
    );
  }

  static Future<OrganicMapsLaunchResult> launchItinerary(
    CompassItinerary itinerary, {
    TravelMode mode = TravelMode.car,
  }) async {
    final stops = itinerary.stops
        .where((stop) => stop.place.hasCoordinates)
        .map(
          (stop) => _OrganicMapsStop(
            latitude: stop.place.latitude!,
            longitude: stop.place.longitude!,
            name: stop.place.name,
          ),
        )
        .toList(growable: false);
    if (stops.isEmpty) return OrganicMapsLaunchResult.invalidDestination;

    return _launch(
      _buildRouteUri(stops: stops, mode: mode),
      lastDestination: _LastDestination(
        name: stops.last.name,
        latitude: stops.last.latitude,
        longitude: stops.last.longitude,
        mode: mode,
      ),
    );
  }

  static Future<Map<String, dynamic>?> readLastDestination() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_lastDestinationKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final value = jsonDecode(encoded);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> openDownloadPage() => launchUrl(
        downloadUri,
        mode: LaunchMode.externalApplication,
      );

  static Uri _buildRouteUri({
    required List<_OrganicMapsStop> stops,
    required TravelMode mode,
  }) {
    if (stops.isEmpty) {
      return Uri.parse('om://v2/nav');
    }
    final destination = stops.last;
    final intermediateStops = stops.take(stops.length - 1).toList();
    final parameters = <String, String>{
      'origin': 'currentLocation',
      'destination': '${destination.latitude},${destination.longitude}',
      'destination_name': destination.name,
      'mode': _organicMode(mode),
      'callback': _callbackUri,
    };
    if (intermediateStops.isNotEmpty) {
      parameters['waypoints'] = intermediateStops
          .map((stop) => '${stop.latitude},${stop.longitude}')
          .join('|');
      parameters['waypoint_names'] =
          intermediateStops.map((stop) => stop.name).join('|');
    }
    return Uri(
      scheme: 'om',
      host: 'v2',
      path: '/nav',
      queryParameters: parameters,
    );
  }

  static String _organicMode(TravelMode mode) => switch (mode) {
        TravelMode.car => 'drive',
        TravelMode.foot => 'pedestrian',
        // Organic Maps has no motorcycle mode; driving is the closest route.
        TravelMode.motorcycle => 'drive',
      };

  static Future<OrganicMapsLaunchResult> _launch(
    Uri uri, {
    required _LastDestination lastDestination,
  }) async {
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) return OrganicMapsLaunchResult.unavailable;

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) return OrganicMapsLaunchResult.failed;

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _lastDestinationKey,
        jsonEncode(lastDestination.toJson()),
      );
      return OrganicMapsLaunchResult.launched;
    } catch (error, stackTrace) {
      debugPrint('Organic Maps launch failed: $error\n$stackTrace');
      return OrganicMapsLaunchResult.failed;
    }
  }
}

class _OrganicMapsStop {
  const _OrganicMapsStop({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  final double latitude;
  final double longitude;
  final String name;
}

class _LastDestination {
  const _LastDestination({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.mode,
  });

  final String name;
  final double latitude;
  final double longitude;
  final TravelMode mode;

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'mode': mode.name,
        'savedAt': DateTime.now().toIso8601String(),
      };
}
