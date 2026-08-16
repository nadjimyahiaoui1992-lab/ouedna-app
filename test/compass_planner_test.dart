import 'package:flutter_test/flutter_test.dart';
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

  test('Souf Compass assigns ordered visit times from the selected start', () {
    final start = DateTime(2026, 8, 16, 9);
    final itinerary = planner.compose(
      places: [
        place(id: 1, category: 'تراث', rating: 5, longitude: 6.86),
        place(id: 2, category: 'تراث', rating: 4.8, longitude: 6.87),
      ],
      preferences: CompassPreferences(
        length: JourneyLength.quick,
        startAt: start,
      ),
    );

    expect(itinerary.startAt, isNotNull);
    expect(itinerary.stops.first.arrivalAt!.isAfter(start), isTrue);
    expect(
      itinerary.stops[1].arrivalAt!.isAfter(itinerary.stops.first.departureAt!),
      isTrue,
    );
    expect(itinerary.stops[1].distanceMeters, greaterThan(0));
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
}
