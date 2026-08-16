import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';

enum JourneyLength { quick, halfDay, fullDay }

class CompassPreferences {
  const CompassPreferences({
    this.length = JourneyLength.halfDay,
    this.categories = const <String>{},
    this.origin,
    this.startAt,
    this.visitDuration = const Duration(minutes: 75),
  });

  final JourneyLength length;
  final Set<String> categories;
  final LatLng? origin;
  final DateTime? startAt;
  final Duration visitDuration;
}

class CompassStop {
  const CompassStop({
    required this.place,
    this.distanceMeters,
    this.order = 0,
    this.arrivalAt,
    this.departureAt,
    this.travelDuration = Duration.zero,
  });

  final Place place;
  final double? distanceMeters;
  final int order;
  final DateTime? arrivalAt;
  final DateTime? departureAt;
  final Duration travelDuration;

  Duration get visitDuration => arrivalAt != null && departureAt != null
      ? departureAt!.difference(arrivalAt!)
      : Duration.zero;
}

class CompassItinerary {
  const CompassItinerary({required this.stops});
  final List<CompassStop> stops;
  bool get isEmpty => stops.isEmpty;

  DateTime? get startAt => stops.isEmpty ? null : stops.first.arrivalAt;
  DateTime? get endAt => stops.isEmpty ? null : stops.last.departureAt;
}
