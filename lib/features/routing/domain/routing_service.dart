import 'routing_models.dart';
abstract interface class RoutingService {
  Future<RoutingResult> calculateRoute({
    required int placeId,
    required RoutePoint origin,
    required RoutePoint destination,
    required TravelMode mode,
    bool alternatives = false,
  });
}
