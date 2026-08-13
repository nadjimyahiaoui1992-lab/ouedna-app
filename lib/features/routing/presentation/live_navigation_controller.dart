import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';

enum NavigationVoiceEventType { start, instruction, rerouting, arrival }

class NavigationVoiceEvent {
  const NavigationVoiceEvent(this.type, this.message);

  final NavigationVoiceEventType type;
  final String message;
}

class LiveNavigationController extends ChangeNotifier {
  LiveNavigationController({
    required this.place,
    required this.routingService,
    LocationService? locationService,
    TravelMode initialMode = TravelMode.car,
  })  : _locationService = locationService ?? LocationService(),
        mode = initialMode;

  final Place place;
  final RoutingService routingService;
  final LocationService _locationService;
  final StreamController<NavigationVoiceEvent> _voiceEvents =
      StreamController<NavigationVoiceEvent>.broadcast();
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastRerouteAt;

  TravelMode mode;
  RoutingResult? result;
  LatLng? currentPosition;
  bool isLoading = false;
  bool isActive = false;
  bool isRerouting = false;
  String? error;
  int activeStepIndex = 0;
  double remainingDistanceMeters = 0;
  double remainingDurationSeconds = 0;

  Stream<NavigationVoiceEvent> get voiceEvents => _voiceEvents.stream;

  Future<void> prepareRoute({bool announceReroute = false}) async {
    if (place.latitude == null || place.longitude == null) {
      error = 'لا تتوفر إحداثيات صحيحة لهذا المعلم بعد.';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      await _calculateFromPosition(position, announceReroute: announceReroute);
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeMode(TravelMode nextMode) async {
    if (mode == nextMode) return;
    mode = nextMode;
    await prepareRoute();
  }

  Future<void> start() async {
    if (result == null) {
      await prepareRoute();
      if (result == null || error != null) return;
    }
    if (isActive) return;

    isActive = true;
    error = null;
    notifyListeners();
    _voiceEvents.add(const NavigationVoiceEvent(
      NavigationVoiceEventType.start,
      'بدأت الملاحة الحية. اتبع المسار الظاهر على الخريطة.',
    ));
    _announceCurrentInstruction();

    await _positionSubscription?.cancel();
    _positionSubscription = _locationService.watchNavigationPosition().listen(
      _onLivePosition,
      onError: (Object exception) {
        error = 'توقف تتبع الموقع: $exception';
        notifyListeners();
      },
    );
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!isActive) return;
    isActive = false;
    isRerouting = false;
    notifyListeners();
  }

  Future<void> _calculateFromPosition(
    Position position, {
    bool announceReroute = false,
  }) async {
    currentPosition = LatLng(position.latitude, position.longitude);
    final routingResult = await routingService.calculateRoute(
      placeId: place.id,
      origin: RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      destination:
          RoutePoint(latitude: place.latitude!, longitude: place.longitude!),
      mode: mode,
    );
    result = routingResult;
    activeStepIndex = 0;
    final route = _route;
    if (route != null) {
      remainingDistanceMeters = route.distanceMeters;
      remainingDurationSeconds = route.durationSeconds;
    }
    if (announceReroute) {
      _voiceEvents.add(const NavigationVoiceEvent(
        NavigationVoiceEventType.rerouting,
        'تم تحديث المسار. اتبع التعليمات الجديدة.',
      ));
      _announceCurrentInstruction();
    }
  }

  Future<void> _onLivePosition(Position position) async {
    if (!isActive) return;
    currentPosition = LatLng(position.latitude, position.longitude);
    final route = _route;
    if (route == null || route.geometry.isEmpty) {
      notifyListeners();
      return;
    }

    final distanceToDestination = _distance.as(
      LengthUnit.Meter,
      currentPosition!,
      LatLng(place.latitude!, place.longitude!),
    );
    if (distanceToDestination <= 25) {
      remainingDistanceMeters = 0;
      remainingDurationSeconds = 0;
      notifyListeners();
      _voiceEvents.add(const NavigationVoiceEvent(
        NavigationVoiceEventType.arrival,
        'وصلت إلى وجهتك. نتمنى لك زيارة ممتعة.',
      ));
      await stop();
      return;
    }

    final closestIndex =
        _closestGeometryIndex(route.geometry, currentPosition!);
    final deviation = _distance.as(
      LengthUnit.Meter,
      currentPosition!,
      route.geometry[closestIndex],
    );
    if (deviation > 55) {
      final canReroute = _lastRerouteAt == null ||
          DateTime.now().difference(_lastRerouteAt!) >
              const Duration(seconds: 15);
      if (canReroute && !isRerouting) {
        _lastRerouteAt = DateTime.now();
        isRerouting = true;
        notifyListeners();
        try {
          await _calculateFromPosition(position, announceReroute: true);
        } catch (_) {
          error = 'تعذر تحديث المسار الآن. سنحاول مجدداً عند تغير موقعك.';
        } finally {
          isRerouting = false;
          notifyListeners();
        }
        return;
      }
    }

    final nextStepIndex = _activeStepFor(route, closestIndex);
    _updateRemainingProgress(route, closestIndex);
    final changedStep = nextStepIndex != activeStepIndex;
    activeStepIndex = nextStepIndex;
    notifyListeners();
    if (changedStep) _announceCurrentInstruction();
  }

  RouteOption? get _route =>
      result?.routes.isNotEmpty == true ? result!.routes.first : null;

  int _closestGeometryIndex(List<LatLng> geometry, LatLng point) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < geometry.length; index++) {
      final candidateDistance =
          _distance.as(LengthUnit.Meter, point, geometry[index]);
      if (candidateDistance < nearestDistance) {
        nearestDistance = candidateDistance;
        nearestIndex = index;
      }
    }
    return nearestIndex;
  }

  int _activeStepFor(RouteOption route, int geometryIndex) {
    if (route.steps.isEmpty) return 0;
    for (var index = 0; index < route.steps.length; index++) {
      if (route.steps[index].endGeometryIndex >= geometryIndex) return index;
    }
    return route.steps.length - 1;
  }

  void _updateRemainingProgress(RouteOption route, int geometryIndex) {
    var remaining = 0.0;
    for (var index = geometryIndex;
        index < route.geometry.length - 1;
        index++) {
      remaining += _distance.as(
        LengthUnit.Meter,
        route.geometry[index],
        route.geometry[index + 1],
      );
    }
    remainingDistanceMeters =
        remaining.clamp(0, route.distanceMeters).toDouble();
    final ratio = route.distanceMeters <= 0
        ? 0.0
        : (remainingDistanceMeters / route.distanceMeters).clamp(0.0, 1.0);
    remainingDurationSeconds = route.durationSeconds * ratio;
  }

  void _announceCurrentInstruction() {
    final route = _route;
    if (route == null || route.steps.isEmpty) return;
    final step = route.steps[activeStepIndex.clamp(0, route.steps.length - 1)];
    final street = step.streetName == null ? '' : ' باتجاه ${step.streetName}';
    final message = switch (step.maneuver) {
      'left' || 'slight_left' || 'sharp_left' => 'انعطف يساراً$street',
      'right' || 'slight_right' || 'sharp_right' => 'انعطف يميناً$street',
      'u_turn' => 'استدر للخلف$street',
      'roundabout' => 'تابع عبر الدوار$street',
      'arrive' => 'وصلت إلى وجهتك',
      _ => 'تابع للأمام$street',
    };
    _voiceEvents.add(NavigationVoiceEvent(
      NavigationVoiceEventType.instruction,
      message,
    ));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _voiceEvents.close();
    super.dispose();
  }
}
