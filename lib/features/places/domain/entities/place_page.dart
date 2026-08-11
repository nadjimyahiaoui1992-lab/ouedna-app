import 'place.dart';

class PlacePage {
  const PlacePage({
    required this.places,
    required this.offset,
    required this.limit,
  });

  final List<Place> places;
  final int offset;
  final int limit;

  bool get hasMore => places.length >= limit;
}
