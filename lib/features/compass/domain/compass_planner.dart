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
    candidates.sort((a, b) {
      if (origin != null) {
        final distanceCompare = _distanceSquared(a, origin)
            .compareTo(_distanceSquared(b, origin));
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
    return CompassItinerary(
      stops: candidates
          .take(maxStops)
          .toList(growable: false)
          .asMap()
          .entries
          .map((entry) => CompassStop(
                place: entry.value,
                order: entry.key + 1,
                distanceMeters: origin == null ? null : _distanceMeters(entry.value, origin),
              ))
          .toList(growable: false),
    );
  }

  double _distanceSquared(Place place, dynamic origin) {
    final latitude = (place.latitude! - origin.latitude) * math.pi / 180;
    final longitude = (place.longitude! - origin.longitude) * math.pi / 180;
    return latitude * latitude + longitude * longitude;
  }

  double _distanceMeters(Place place, dynamic origin) {
    const earthRadius = 6371000.0;
    final latitude1 = place.latitude! * math.pi / 180;
    final latitude2 = origin.latitude * math.pi / 180;
    final deltaLatitude = (origin.latitude - place.latitude!) * math.pi / 180;
    final deltaLongitude = (origin.longitude - place.longitude!) * math.pi / 180;
    final a = math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.cos(latitude1) * math.cos(latitude2) *
            math.sin(deltaLongitude / 2) * math.sin(deltaLongitude / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
