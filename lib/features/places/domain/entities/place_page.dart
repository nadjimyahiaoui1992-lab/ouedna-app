import 'place.dart';

class PlacePage {
  const PlacePage({
    required this.places,
    this.hasMore = false,
    this.offset = 0,
    this.limit = 20,
  });

  final List<Place> places;
  final bool hasMore;
  final int offset;
  final int limit;
}
