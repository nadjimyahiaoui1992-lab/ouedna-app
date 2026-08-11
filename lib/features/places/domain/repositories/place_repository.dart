import '../entities/place.dart';

abstract interface class PlaceRepository {
  Future<List<Place>> getPublishedPlaces({String? query});
}
