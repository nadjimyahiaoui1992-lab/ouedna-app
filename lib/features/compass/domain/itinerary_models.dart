import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';

enum JourneyLength {
  quick,
  halfDay,
  fullDay;

  String get label => switch (this) {
        JourneyLength.quick => 'سريع',
        JourneyLength.halfDay => 'نصف يوم',
        JourneyLength.fullDay => 'يوم كامل',
      };

  int get targetStops => switch (this) {
        JourneyLength.quick => 2,
        JourneyLength.halfDay => 3,
        JourneyLength.fullDay => 5,
      };
}

class CompassPreferences {
  const CompassPreferences({
    required this.length,
    required this.categories,
    this.origin,
  });

  final JourneyLength length;
  final Set<String> categories;
  final LatLng? origin;
}

class CompassStop {
  const CompassStop({
    required this.place,
    required this.order,
  });

  final Place place;
  final int order;
}

class CompassItinerary {
  const CompassItinerary({
    required this.stops,
    required this.preferences,
  });

  final List<CompassStop> stops;
  final CompassPreferences preferences;

  bool get isEmpty => stops.isEmpty;
}
