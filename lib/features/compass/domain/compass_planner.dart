import 'dart:math' as math;

import '../../places/domain/entities/place.dart';
import 'itinerary_models.dart';

class CompassPlanner {
  const CompassPlanner();

  CompassItinerary compose({
    required List<Place> places,
    required CompassPreferences preferences,
  }) {
    final selectedCategories = preferences.categories;
    final candidates = places.where((place) {
      if (!place.hasCoordinates) return false;
      if (selectedCategories.isEmpty) return true;
      return selectedCategories.contains(place.category);
    }).toList();

    final origin = preferences.origin;
    final originPoint =
        origin == null ? null : LatLngLike(origin.latitude, origin.longitude);
    candidates.sort((a, b) {
      if (originPoint != null) {
        final distanceCompare = _distanceSquared(a, originPoint)
            .compareTo(_distanceSquared(b, originPoint));
        if (distanceCompare != 0) return distanceCompare;
      }
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;
      return a.name.compareTo(b.name);
    });

    final maxStops = switch (preferences.length) {
      JourneyLength.quick => 2,
      JourneyLength.halfDay => 5,
      JourneyLength.fullDay => 9,
    };
    final selected = candidates.take(maxStops).toList(growable: false);
    if (selected.isEmpty) return const CompassItinerary(stops: []);

    final now = DateTime.now();
    final requestedStart =
        preferences.startAt ?? DateTime(now.year, now.month, now.day, 9, 0);
    var cursor = requestedStart;
    LatLngLike? previous = originPoint;
    final stops = <CompassStop>[];

    for (var index = 0; index < selected.length; index++) {
      final place = selected[index];
      final distanceMeters = origin == null && previous == null
          ? null
          : _distanceMetersBetween(
              previous!.latitude,
              previous.longitude,
              place.latitude!,
              place.longitude!,
            );
      final travelDuration = _travelDuration(distanceMeters);
      final arrivalAt = cursor.add(travelDuration);
      final departureAt = arrivalAt.add(preferences.visitDuration);
      stops.add(
        CompassStop(
          place: place,
          order: index + 1,
          distanceMeters: distanceMeters,
          arrivalAt: arrivalAt,
          departureAt: departureAt,
          travelDuration: travelDuration,
        ),
      );
      cursor = departureAt;
      previous = LatLngLike(place.latitude!, place.longitude!);
    }

    return CompassItinerary(stops: stops);
  }

  double _distanceSquared(Place place, LatLngLike origin) {
    final latitude = (place.latitude! - origin.latitude) * math.pi / 180;
    final longitude = (place.longitude! - origin.longitude) * math.pi / 180;
    return latitude * latitude + longitude * longitude;
  }

  double _distanceMetersBetween(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;
    final firstLatitude = latitude1 * math.pi / 180;
    final secondLatitude = latitude2 * math.pi / 180;
    final deltaLatitude = (latitude2 - latitude1) * math.pi / 180;
    final deltaLongitude = (longitude2 - longitude1) * math.pi / 180;
    final a = math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.cos(firstLatitude) *
            math.cos(secondLatitude) *
            math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Duration _travelDuration(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters <= 1) return Duration.zero;
    final minutes = (distanceMeters / 1000 / 25 * 60).ceil();
    return Duration(minutes: math.max(6, math.min(minutes, 75)));
  }
}

class LatLngLike {
  const LatLngLike(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}
