import '../entities/place.dart';

abstract interface class PlaceRepository {
  Future<List<Place>> getPublishedPlaces({String? query});

  /// Emits when Souf360 changes the public places catalogue.
  Stream<void> watchPublishedPlaces();
}
