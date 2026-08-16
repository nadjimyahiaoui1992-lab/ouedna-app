import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ouedna_app/features/compass/domain/compass_planner.dart';
import 'package:ouedna_app/features/compass/domain/itinerary_models.dart';
import 'package:ouedna_app/features/places/domain/entities/place.dart';

void main() {
  const planner = CompassPlanner();

  Place place({
    required int id,
    required String category,
    required double rating,
    double? latitude = 33.36,
    double? longitude = 6.86,
    String? openingHours,
  }) =>
      Place(
        id: id,
        name: 'مكان $id',
        category: category,
        description: 'وصف',
        address: 'الوادي',
        rating: rating,
        latitude: latitude,
        longitude: longitude,
        openingHours: openingHours,
      );

  test('Souf Compass keeps only the selected published categories', () {
    final itinerary = planner.compose(
      places: [
        place(id: 1, category: 'معلم تراثي', rating: 4.8),
        place(id: 2, category: 'فنادق ومنتجعات', rating: 5),
        place(id: 3, category: 'معلم تراثي', rating: 4.5),
      ],
      preferences: const CompassPreferences(
        length: JourneyLength.halfDay,
        categories: {'معلم تراثي'},
      ),
    );

    expect(itinerary.stops, hasLength(2));
    expect(
      itinerary.stops.map((stop) => stop.place.category),
      everyElement('معلم تراثي'),
    );
    expect(itinerary.stops.first.place.id, 1);
  });

  test(
      'Souf Compass never creates an itinerary from places without coordinates',
      () {
    final itinerary = planner.compose(
      places: [
        place(
          id: 1,
          category: 'معلم تراثي',
          rating: 5,
          latitude: null,
          longitude: null,
        ),
      ],
      preferences: const CompassPreferences(
        length: JourneyLength.quick,
        categories: {},
      ),
    );

    expect(itinerary.isEmpty, isTrue);
  });

  test('Souf Compass respects opening hours and exposes a precise schedule',
      () {
    final itinerary = planner.compose(
      places: [
        place(
          id: 1,
          category: 'معلم تراثي',
          rating: 5,
          openingHours: '10:00 - 18:00',
        ),
      ],
      preferences: CompassPreferences(
        length: JourneyLength.quick,
        origin: const LatLng(33.36, 6.86),
        startAt: DateTime(2026, 8, 16, 9),
      ),
    );

    expect(itinerary.stops, hasLength(1));
    expect(itinerary.stops.single.arrivalAt?.hour, 10);
    expect(itinerary.stops.single.departureAt?.hour, 11);
    expect(itinerary.stops.single.travelIsEstimated, isTrue);
  });

  test('Souf Compass never exceeds the selected time budget', () {
    final itinerary = planner.compose(
      places: [
        place(id: 1, category: 'معلم تراثي', rating: 5),
        place(id: 2, category: 'معلم تراثي', rating: 4.9),
        place(id: 3, category: 'معلم تراثي', rating: 4.8),
      ],
      preferences: CompassPreferences(
        length: JourneyLength.custom,
        availableMinutes: 120,
        origin: const LatLng(33.36, 6.86),
        startAt: DateTime(2026, 8, 16, 9),
      ),
    );

    expect(itinerary.totalMinutes, lessThanOrEqualTo(120));
    expect(itinerary.stops.length, 2);
  });

  test('Souf Compass supports manual selection and preferred order', () {
    final itinerary = planner.compose(
      places: [
        place(id: 1, category: 'معلم تراثي', rating: 5),
        place(id: 2, category: 'معلم تراثي', rating: 4),
        place(id: 3, category: 'معلم تراثي', rating: 3),
      ],
      preferences: const CompassPreferences(
        length: JourneyLength.quick,
        selectedPlaceIds: {2, 3},
        preferredOrderIds: [3, 2],
      ),
    );

    expect(itinerary.stops.map((stop) => stop.place.id), [3, 2]);
  });
}
