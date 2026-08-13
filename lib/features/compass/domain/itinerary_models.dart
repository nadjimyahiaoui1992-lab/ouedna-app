import '../../places/domain/entities/place.dart';
import 'package:latlong2/latlong.dart';

enum JourneyLength { quick, halfDay, fullDay }

class CompassPreferences {
  const CompassPreferences({
    this.length = JourneyLength.halfDay,
    this.categories = const <String>{},
    this.origin,
  });

  final JourneyLength length;
  final Set<String> categories;
  final LatLng? origin;
}

class CompassStop {
  const CompassStop({required this.place, this.distanceMeters, this.order = 0});
  final Place place;
  final double? distanceMeters;
  final int order;
}

class CompassItinerary {
  const CompassItinerary({required this.stops});
  final List<CompassStop> stops;
  bool get isEmpty => stops.isEmpty;
}
