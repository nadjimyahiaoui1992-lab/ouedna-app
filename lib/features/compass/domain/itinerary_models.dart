import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';
import '../../routing/domain/routing_models.dart';

enum JourneyLength { quick, fourHours, halfDay, fullDay, custom }

extension JourneyLengthExt on JourneyLength {
  String get label => switch (this) {
        JourneyLength.quick => 'ساعتان',
        JourneyLength.fourHours => '4 ساعات',
        JourneyLength.halfDay => 'نصف يوم',
        JourneyLength.fullDay => 'يوم كامل',
        JourneyLength.custom => 'مخصص',
      };

  int get defaultMinutes => switch (this) {
        JourneyLength.quick => 120,
        JourneyLength.fourHours => 240,
        JourneyLength.halfDay => 360,
        JourneyLength.fullDay => 600,
        JourneyLength.custom => 240,
      };
}

class CompassPreferences {
  const CompassPreferences({
    this.length = JourneyLength.halfDay,
    this.categories = const <String>{},
    this.origin,
    this.startAt,
    this.availableMinutes,
    this.selectedPlaceIds = const <int>{},
    this.preferredOrderIds = const <int>[],
    this.visitDurationOverrides = const <int, int>{},
    this.travelMode = TravelMode.car,
  });

  final JourneyLength length;
  final Set<String> categories;
  final LatLng? origin;
  final DateTime? startAt;
  final int? availableMinutes;
  final Set<int> selectedPlaceIds;
  final List<int> preferredOrderIds;
  final Map<int, int> visitDurationOverrides;
  final TravelMode travelMode;

  int get budgetMinutes => availableMinutes ?? length.defaultMinutes;
}

class CompassLeg {
  const CompassLeg({
    required this.from,
    required this.to,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.isEstimated = false,
  });

  final LatLng from;
  final LatLng to;
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometry;
  final bool isEstimated;
}

class CompassStop {
  const CompassStop({
    required this.place,
    this.distanceMeters,
    this.order = 0,
    this.arrivalAt,
    this.departureAt,
    this.visitMinutes = 45,
    this.travelSeconds = 0,
    this.travelIsEstimated = true,
    this.leg,
  });

  final Place place;
  final double? distanceMeters;
  final int order;
  final DateTime? arrivalAt;
  final DateTime? departureAt;
  final int visitMinutes;
  final double travelSeconds;
  final bool travelIsEstimated;
  final CompassLeg? leg;

  bool get hasSchedule => arrivalAt != null && departureAt != null;
}

class CompassItinerary {
  const CompassItinerary({
    required this.stops,
    this.startAt,
    this.endAt,
    this.startLocation,
    this.totalTravelSeconds = 0,
    this.totalVisitMinutes = 0,
    this.hasEstimatedTravel = true,
  });

  final List<CompassStop> stops;
  final DateTime? startAt;
  final DateTime? endAt;
  final LatLng? startLocation;
  final double totalTravelSeconds;
  final int totalVisitMinutes;
  final bool hasEstimatedTravel;

  bool get isEmpty => stops.isEmpty;
  int get totalMinutes => (totalTravelSeconds / 60).round() + totalVisitMinutes;

  List<LatLng> get geometry {
    final result = <LatLng>[];
    for (final stop in stops) {
      final points = stop.leg?.geometry ?? const <LatLng>[];
      if (points.isEmpty) continue;
      if (result.isEmpty) {
        result.addAll(points);
      } else {
        result.addAll(points.skip(1));
      }
    }
    return result;
  }
}
