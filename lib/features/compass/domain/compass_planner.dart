import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';
import '../../routing/domain/routing_models.dart';
import 'itinerary_models.dart';

class CompassPlanner {
  const CompassPlanner();

  CompassItinerary compose({
    required List<Place> places,
    required CompassPreferences preferences,
    Map<int, CompassLeg>? routedLegs,
  }) {
    final candidates = places.where((place) {
      if (!place.hasCoordinates) return false;
      if (preferences.selectedPlaceIds.isNotEmpty &&
          !preferences.selectedPlaceIds.contains(place.id)) {
        return false;
      }
      if (preferences.categories.isNotEmpty &&
          !preferences.categories.contains(place.category)) {
        return false;
      }
      return true;
    }).toList(growable: true);

    final start = preferences.startAt ?? _roundToMinute(DateTime.now());
    final budget = Duration(minutes: preferences.budgetMinutes);
    final preferred = <int, int>{
      for (var index = 0; index < preferences.preferredOrderIds.length; index++)
        preferences.preferredOrderIds[index]: index,
    };
    final stops = <CompassStop>[];
    var current = preferences.origin;
    var cursor = start;
    var totalTravelSeconds = 0.0;
    var totalVisitMinutes = 0;
    var available = candidates;
    var order = 1;

    while (available.isNotEmpty) {
      final next = _chooseNext(
        available,
        current: current,
        cursor: cursor,
        preferred: preferred,
        travelMode: preferences.travelMode,
      );
      if (next == null) break;

      final visitMinutes = preferences.visitDurationOverrides[next.id] ??
          _defaultVisitMinutes(next);
      final leg = _legFor(
        from: current,
        to: LatLng(next.latitude!, next.longitude!),
        mode: preferences.travelMode,
        routedLegs: routedLegs,
        placeId: next.id,
      );
      var arrival = cursor.add(Duration(seconds: leg.durationSeconds.round()));
      final opening = _openingWindow(next.openingHours, arrival);
      if (opening == null && next.openingHours?.trim().isNotEmpty == true) {
        available = available.where((place) => place.id != next.id).toList();
        continue;
      }
      if (opening != null && arrival.isBefore(opening.opensAt)) {
        arrival = opening.opensAt;
      }
      final departure = arrival.add(Duration(minutes: visitMinutes));
      final elapsed = departure.difference(start);
      if (elapsed > budget && stops.isNotEmpty) break;
      if (elapsed > budget && stops.isEmpty) {
        available = available.where((place) => place.id != next.id).toList();
        continue;
      }

      stops.add(
        CompassStop(
          place: next,
          order: order++,
          distanceMeters: leg.distanceMeters,
          arrivalAt: arrival,
          departureAt: departure,
          visitMinutes: visitMinutes,
          travelSeconds: leg.durationSeconds,
          travelIsEstimated: leg.isEstimated,
          leg: leg,
        ),
      );
      totalTravelSeconds += leg.durationSeconds;
      totalVisitMinutes += visitMinutes;
      current = LatLng(next.latitude!, next.longitude!);
      cursor = departure;
      available = available.where((place) => place.id != next.id).toList();
    }

    final endAt = stops.isEmpty ? null : stops.last.departureAt;
    return CompassItinerary(
      stops: stops,
      startAt: stops.isEmpty ? null : start,
      endAt: endAt,
      startLocation: preferences.origin,
      totalTravelSeconds: totalTravelSeconds,
      totalVisitMinutes: totalVisitMinutes,
      hasEstimatedTravel: stops.any((stop) => stop.travelIsEstimated),
    );
  }

  Place? _chooseNext(
    List<Place> places, {
    required LatLng? current,
    required DateTime cursor,
    required Map<int, int> preferred,
    required TravelMode travelMode,
  }) {
    final ranked = places.toList(growable: false)
      ..sort((a, b) {
        final preferredCompare =
            (preferred[a.id] ?? 1 << 20).compareTo(preferred[b.id] ?? 1 << 20);
        if (preferredCompare != 0 && preferred.isNotEmpty) {
          return preferredCompare;
        }
        if (current != null) {
          final distanceCompare = _distanceMeters(
                  current, LatLng(a.latitude!, a.longitude!))
              .compareTo(
                  _distanceMeters(current, LatLng(b.latitude!, b.longitude!)));
          if (distanceCompare != 0) return distanceCompare;
        }
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return a.name.compareTo(b.name);
      });
    return ranked.isEmpty ? null : ranked.first;
  }

  CompassLeg _legFor({
    required LatLng? from,
    required LatLng to,
    required TravelMode mode,
    required Map<int, CompassLeg>? routedLegs,
    required int placeId,
  }) {
    final routed = routedLegs?[placeId];
    if (routed != null) return routed;
    if (from == null) {
      return CompassLeg(
        from: to,
        to: to,
        distanceMeters: 0,
        durationSeconds: 0,
        geometry: [to],
      );
    }
    final distance = _distanceMeters(from, to);
    final speedMetersPerSecond = switch (mode) {
      TravelMode.car => 11.1,
      TravelMode.foot => 1.35,
      TravelMode.motorcycle => 13.8,
    };
    return CompassLeg(
      from: from,
      to: to,
      distanceMeters: distance,
      durationSeconds: distance / speedMetersPerSecond,
      geometry: [from, to],
      isEstimated: true,
    );
  }

  int _defaultVisitMinutes(Place place) {
    final text = '${place.category} ${place.subCategory ?? ''}'.toLowerCase();
    if (text.contains('مطعم') || text.contains('restaurant')) return 60;
    if (text.contains('فندق') || text.contains('hotel')) return 90;
    if (text.contains('طبيعي') ||
        text.contains('طبيعة') ||
        text.contains('nature')) {
      return 75;
    }
    if (text.contains('تراث') ||
        text.contains('متحف') ||
        text.contains('ديني')) {
      return 60;
    }
    if (text.contains('سوق') || text.contains('متجر')) return 45;
    return 45;
  }

  _OpeningWindow? _openingWindow(String? raw, DateTime at) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final matches = RegExp(
      r'(\d{1,2})\s*[:٫\.]\s*(\d{2})\s*(?:-|–|—|→|الى|إلى|to)\s*(\d{1,2})\s*[:٫\.]\s*(\d{2})',
      caseSensitive: false,
    ).firstMatch(value);
    if (matches == null) return null;
    final openHour = int.parse(matches.group(1)!);
    final openMinute = int.parse(matches.group(2)!);
    final closeHour = int.parse(matches.group(3)!);
    final closeMinute = int.parse(matches.group(4)!);
    if (openHour > 23 ||
        closeHour > 23 ||
        openMinute > 59 ||
        closeMinute > 59) {
      return null;
    }
    final opens = DateTime(at.year, at.month, at.day, openHour, openMinute);
    var closes = DateTime(at.year, at.month, at.day, closeHour, closeMinute);
    if (!closes.isAfter(opens)) closes = closes.add(const Duration(days: 1));
    if (at.isAfter(closes)) return null;
    return _OpeningWindow(opensAt: opens, closesAt: closes);
  }

  DateTime _roundToMinute(DateTime value) =>
      DateTime(value.year, value.month, value.day, value.hour, value.minute);

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final latitude1 = a.latitude * math.pi / 180;
    final latitude2 = b.latitude * math.pi / 180;
    final deltaLatitude = (b.latitude - a.latitude) * math.pi / 180;
    final deltaLongitude = (b.longitude - a.longitude) * math.pi / 180;
    final haversine =
        math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
            math.cos(latitude1) *
                math.cos(latitude2) *
                math.sin(deltaLongitude / 2) *
                math.sin(deltaLongitude / 2);
    return earthRadius *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }
}

class _OpeningWindow {
  const _OpeningWindow({required this.opensAt, required this.closesAt});
  final DateTime opensAt;
  final DateTime closesAt;
}
