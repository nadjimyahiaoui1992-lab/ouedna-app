import '../entities/place.dart';
import '../repositories/place_repository.dart';

class GetPublishedPlaces {
  const GetPublishedPlaces(this._repository);

  final PlaceRepository _repository;

  Future<List<Place>> call({String? query}) =>
      _repository.getPublishedPlaces(query: query);
}
