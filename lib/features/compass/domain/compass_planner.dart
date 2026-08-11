import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';
import 'itinerary_models.dart';

class CompassPlanner {
  const CompassPlanner();

  CompassItinerary compose({
    required List<Place> places,
    required CompassPreferences preferences,
  }) {
    final candidates = places
        .where((place) => place.hasCoordinates)
        .where(
          (place) =>
              preferences.categories.isEmpty ||
              preferences.categories.contains(place.category),
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      return CompassItinerary(stops: const [], preferences: preferences);
    }

    final remaining = [...candidates];
    final selected = <Place>[];
    LatLng? cursor = preferences.origin;

    while (remaining.isNotEmpty &&
        selected.length < preferences.length.targetStops) {
      remaining.sort((left, right) {
        final rightScore =
            _score(right, preferences: preferences, from: cursor);
        final leftScore = _score(left, preferences: preferences, from: cursor);
        return rightScore.compareTo(leftScore);
      });
      final chosen = remaining.removeAt(0);
      selected.add(chosen);
      cursor = LatLng(chosen.latitude!, chosen.longitude!);
    }

    return CompassItinerary(
      preferences: preferences,
      stops: [
        for (var index = 0; index < selected.length; index++)
          CompassStop(place: selected[index], order: index + 1),
      ],
    );
  }

  double _score(
    Place place, {
    required CompassPreferences preferences,
    required LatLng? from,
  }) {
    var score = (place.rating ?? 0) * 100;
    if (preferences.categories.contains(place.category)) score += 25;
    if (from != null) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        from,
        LatLng(place.latitude!, place.longitude!),
      );
      // This is a ranking cost only. It is not displayed as navigation distance.
      score -= distance * 4;
    }
    return score;
  }
}
