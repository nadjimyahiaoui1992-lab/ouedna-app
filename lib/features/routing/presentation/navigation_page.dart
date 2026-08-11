import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({
    super.key,
    required this.place,
    required this.routingService,
  });

  final Place place;
  final RoutingService? routingService;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  static const _arrivalRadiusMeters = 50.0;
  static const _offRouteRadiusMeters = 65.0;

  final _mapController = MapController();
  final _locationService = LocationService();
  final _distance = const Distance();
  StreamSubscription<Position>? _positionSubscription;
  Position? _position;
  RoutingResult? _result;
  RouteOption? _selectedRoute;
  TravelMode _mode = TravelMode.car;
  String? _error;
  bool _loading = true;
  bool _navigating = false;
  bool _rerouting = false;
  bool _arrived = false;
  DateTime? _lastRerouteAt;

  @override
  void initState() {
    super.initState();
    _prepareRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _prepareRoute() async {
    if (!widget.place.hasCoordinates) {
      setState(() {
        _loading = false;
        _error = 'الملاحة غير متاحة لأن هذا المكان لا يملك إحداثيات منشورة.';
      });
      return;
    }
    if (widget.routingService == null) {
      setState(() {
        _loading = false;
        _error = 'خدمة الملاحة قيد الإعداد. حاول لاحقاً.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _arrived = false;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      await _calculateRoute();
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحديد موقعك. تحقق من الموقع والاتصال ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _calculateRoute({bool isReroute = false}) async {
    final position = _position;
    final service = widget.routingService;
    if (position == null || service == null) return;
    if (isReroute) {
      setState(() => _rerouting = true);
    }
    try {
      final result = await service.calculateRoute(
        placeId: widget.place.id,
        origin: RoutePoint(
            latitude: position.latitude, longitude: position.longitude),
        mode: _mode,
        alternatives: true,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _selectedRoute = result.routes.first;
        _loading = false;
        _rerouting = false;
        _error = null;
      });
      _focusRoute(result.routes.first);
    } on RoutingException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rerouting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rerouting = false;
        _error = 'تعذر حساب مسار جديد. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

  void _focusRoute(RouteOption route) {
    if (route.geometry.length < 2) return;
    final points = route.geometry;
    final center = LatLng(
      points.map((point) => point.latitude).reduce((a, b) => a + b) /
          points.length,
      points.map((point) => point.longitude).reduce((a, b) => a + b) /
          points.length,
    );
    _mapController.move(center, 12);
  }

  Future<void> _startNavigation() async {
    if (_selectedRoute == null) return;
    await _positionSubscription?.cancel();
    setState(() => _navigating = true);
    _positionSubscription = _locationService.watchPosition().listen(
      _onPosition,
      onError: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('تعذر متابعة الموقع. ستبقى الخريطة قابلة للاستخدام.')),
          );
        }
      },
    );
  }

  void _onPosition(Position position) {
    if (!mounted) return;
    setState(() => _position = position);
    _mapController.move(LatLng(position.latitude, position.longitude), 16);
    final route = _selectedRoute;
    if (route == null) return;

    final closest = _closestGeometryIndex(route, position);
    final nearestDistance =
        _distanceToGeometryPoint(route.geometry[closest], position);
    final destinationDistance = _distance.as(
      LengthUnit.Meter,
      LatLng(position.latitude, position.longitude),
      LatLng(widget.place.latitude!, widget.place.longitude!),
    );

    if (destinationDistance <= _arrivalRadiusMeters) {
      _positionSubscription?.cancel();
      setState(() {
        _arrived = true;
        _navigating = false;
      });
      _showArrivalSheet();
      return;
    }

    final now = DateTime.now();
    final canReroute = _lastRerouteAt == null ||
        now.difference(_lastRerouteAt!).inSeconds >= 15;
    if (nearestDistance > _offRouteRadiusMeters && !_rerouting && canReroute) {
      _lastRerouteAt = now;
      _calculateRoute(isReroute: true);
    }
  }

  int _closestGeometryIndex(RouteOption route, Position position) {
    var closestIndex = 0;
    var closestDistance = double.infinity;
    final user = LatLng(position.latitude, position.longitude);
    for (var index = 0; index < route.geometry.length; index++) {
      final candidate =
          _distance.as(LengthUnit.Meter, user, route.geometry[index]);
      if (candidate < closestDistance) {
        closestDistance = candidate;
        closestIndex = index;
      }
    }
    return closestIndex;
  }

  double _distanceToGeometryPoint(LatLng point, Position position) =>
      _distance.as(
        LengthUnit.Meter,
        point,
        LatLng(position.latitude, position.longitude),
      );

  double _remainingRouteDistance(RouteOption route, Position? position) {
    if (position == null || route.geometry.length < 2)
      return route.distanceMeters;
    final from = _closestGeometryIndex(route, position);
    var meters = 0.0;
    for (var index = from; index < route.geometry.length - 1; index++) {
      meters += _distance.as(
          LengthUnit.Meter, route.geometry[index], route.geometry[index + 1]);
    }
    return meters.clamp(0, route.distanceMeters);
  }

  RouteStep? _nextStep(RouteOption route, Position? position) {
    if (route.steps.isEmpty) return null;
    final currentIndex =
        position == null ? 0 : _closestGeometryIndex(route, position);
    for (final step in route.steps) {
      if (step.endGeometryIndex >= currentIndex && step.maneuver != 'arrive')
        return step;
    }
    return route.steps.last;
  }

  String _distanceLabel(double meters) => meters < 1000
      ? '${meters.round()} م'
      : '${(meters / 1000).toStringAsFixed(1)} كم';

  String _durationLabel(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes دقيقة';
    return '${minutes ~/ 60} س ${minutes % 60} د';
  }

  String _instructionLabel(RouteStep? step) {
    if (step == null) return 'تابع باتجاه الوجهة';
    final base = switch (step.maneuver) {
      'left' => 'انعطف يساراً',
      'right' => 'انعطف يميناً',
      'slight_left' => 'اتجه قليلاً إلى اليسار',
      'slight_right' => 'اتجه قليلاً إلى اليمين',
      'sharp_left' => 'انعطف بشدة إلى اليسار',
      'sharp_right' => 'انعطف بشدة إلى اليمين',
      'u_turn' => 'استدر للخلف',
      'roundabout' => 'اتجه عبر الدوار',
      'arrive' => 'لقد وصلت إلى وجهتك',
      _ => 'تابع إلى الأمام',
    };
    final street = step.streetName?.trim();
    return street == null || street.isEmpty ? base : '$base إلى $street';
  }

  IconData _maneuverIcon(RouteStep? step) => switch (step?.maneuver) {
        'left' || 'slight_left' || 'sharp_left' => Icons.turn_left_rounded,
        'right' || 'slight_right' || 'sharp_right' => Icons.turn_right_rounded,
        'u_turn' => Icons.u_turn_left_rounded,
        'roundabout' => Icons.roundabout_right_rounded,
        'arrive' => Icons.flag_rounded,
        _ => Icons.straight_rounded,
      };

  void _showArrivalSheet() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded,
                  color: Color(0xFFD9A441), size: 44),
              const SizedBox(height: 10),
              Text('لقد وصلت',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(widget.place.name, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('متابعة الاستكشاف')),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(
        widget.place.latitude ?? 33.367, widget.place.longitude ?? 6.867);
    final route = _selectedRoute;
    final remainingMeters =
        route == null ? 0.0 : _remainingRouteDistance(route, _position);
    final remainingSeconds = route == null || route.distanceMeters <= 0
        ? 0.0
        : route.durationSeconds * (remainingMeters / route.distanceMeters);
    final nextStep = route == null ? null : _nextStep(route, _position);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: destination, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.souf360.app',
              ),
              if (route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route.geometry,
                      color: const Color(0xFF193F38),
                      strokeWidth: 6,
                      borderColor: const Color(0xFFE5B65A),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: destination,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFFD9A441), size: 44),
                  ),
                  if (_position != null)
                    Marker(
                      point: LatLng(_position!.latitude, _position!.longitude),
                      width: 42,
                      height: 42,
                      child: Transform.rotate(
                        angle: (_position!.heading.isFinite &&
                                _position!.heading >= 0)
                            ? _position!.heading * 0.0174532925
                            : 0,
                        child: const Icon(Icons.navigation_rounded,
                            color: Color(0xFF193F38), size: 38),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'رجوع',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  Expanded(
                    child: _DestinationBanner(place: widget.place),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'موقعي',
                    onPressed: _position == null
                        ? _prepareRoute
                        : () => _mapController.move(
                            LatLng(_position!.latitude, _position!.longitude),
                            16),
                    icon: const Icon(Icons.my_location_outlined),
                  ),
                ],
              ),
            ),
          ),
          if (_rerouting)
            const Positioned(
                top: 94,
                right: 22,
                left: 22,
                child: _StatusPill(label: 'إعادة حساب المسار...')),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
                child:
                    _NavigationError(message: _error!, onRetry: _prepareRoute))
          else if (route != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _NavigationPanel(
                mode: _mode,
                routes: _result!.routes,
                selectedRoute: route,
                remainingDistance: _distanceLabel(remainingMeters),
                estimatedTime: _durationLabel(remainingSeconds),
                nextInstruction: _instructionLabel(nextStep),
                nextDistance: nextStep == null
                    ? null
                    : _distanceLabel(nextStep.distanceMeters),
                maneuverIcon: _maneuverIcon(nextStep),
                navigating: _navigating,
                arrived: _arrived,
                onModeChanged: (mode) {
                  if (mode == _mode) return;
                  setState(() => _mode = mode);
                  _calculateRoute();
                },
                onRouteSelected: (value) =>
                    setState(() => _selectedRoute = value),
                onStart: _startNavigation,
              ),
            ),
        ],
      ),
    );
  }
}

class _DestinationBanner extends StatelessWidget {
  const _DestinationBanner({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.96),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الوصول إلى', style: TextStyle(fontSize: 12)),
            Text(place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.mode,
    required this.routes,
    required this.selectedRoute,
    required this.remainingDistance,
    required this.estimatedTime,
    required this.nextInstruction,
    required this.nextDistance,
    required this.maneuverIcon,
    required this.navigating,
    required this.arrived,
    required this.onModeChanged,
    required this.onRouteSelected,
    required this.onStart,
  });

  final TravelMode mode;
  final List<RouteOption> routes;
  final RouteOption selectedRoute;
  final String remainingDistance;
  final String estimatedTime;
  final String nextInstruction;
  final String? nextDistance;
  final IconData maneuverIcon;
  final bool navigating;
  final bool arrived;
  final ValueChanged<TravelMode> onModeChanged;
  final ValueChanged<RouteOption> onRouteSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 14),
                if (!navigating)
                  SegmentedButton<TravelMode>(
                    segments: const [
                      ButtonSegment(
                          value: TravelMode.car,
                          icon: Icon(Icons.directions_car_outlined),
                          label: Text('سيارة')),
                      ButtonSegment(
                          value: TravelMode.foot,
                          icon: Icon(Icons.directions_walk_outlined),
                          label: Text('مشياً')),
                      ButtonSegment(
                          value: TravelMode.bike,
                          icon: Icon(Icons.directions_bike_outlined),
                          label: Text('دراجة')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (value) => onModeChanged(value.first),
                  ),
                if (routes.length > 1 && !navigating) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: routes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return ChoiceChip(
                          label: Text(
                              '${(route.distanceMeters / 1000).toStringAsFixed(1)} كم'),
                          selected: route == selectedRoute,
                          onSelected: (_) => onRouteSelected(route),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                          color: Color(0xFF193F38), shape: BoxShape.circle),
                      child: Icon(maneuverIcon, color: const Color(0xFFE5B65A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nextInstruction,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          if (nextDistance != null) Text('بعد $nextDistance'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(remainingDistance,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        Text('الوقت المتوقع: $estimatedTime'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: navigating || arrived ? null : onStart,
                    icon: Icon(navigating
                        ? Icons.navigation_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(navigating
                        ? 'الملاحة جارية'
                        : arrived
                            ? 'تم الوصول'
                            : 'بدء الملاحة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _NavigationError extends StatelessWidget {
  const _NavigationError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 42),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      );
}
