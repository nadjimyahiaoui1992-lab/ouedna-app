import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.place, this.routingService});

  final Place place;
  final RoutingService? routingService;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  TravelMode _mode = TravelMode.car;
  bool _loading = true;
  String? _error;
  RoutingResult? _result;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    if (widget.place.latitude == null || widget.place.longitude == null) {
      setState(() {
        _loading = false;
        _error = 'لا تتوفر إحداثيات صحيحة لهذا المعلم بعد.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await LocationService().getCurrentPosition();
      final origin = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final destination = RoutePoint(
        latitude: widget.place.latitude!,
        longitude: widget.place.longitude!,
      );
      final result = await widget.routingService?.calculateRoute(
        placeId: widget.place.id,
        origin: origin,
        destination: destination,
        mode: _mode,
      );
      if (result == null) {
        throw const RoutingException('خدمة الملاحة غير متاحة حالياً.');
      }
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectMode(TravelMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _loadRoute();
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude!, widget.place.longitude!);
    final route =
        _result?.routes.isNotEmpty == true ? _result!.routes.first : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الملاحة الذكية',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              Text(
                widget.place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF60706C)),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث الموقع والمسار',
              onPressed: _loading ? null : _loadRoute,
              icon: const Icon(Icons.my_location_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition ?? destination,
                initialZoom: route == null ? 15 : 13.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.ouedna.app.v2',
                ),
                if (route != null && route.geometry.isNotEmpty) ...[
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 11,
                        color: const Color(0x33132E2A),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 6,
                        color: const Color(0xFF1479D1),
                      ),
                    ],
                  ),
                ],
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination,
                      width: 50,
                      height: 60,
                      child: const _DestinationMarker(),
                    ),
                    if (_currentPosition != null)
                      Marker(
                        point: _currentPosition!,
                        width: 52,
                        height: 52,
                        child: const _UserMarker(),
                      ),
                  ],
                ),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _RouteIdentity(
                    destinationName: widget.place.name,
                    hasLocation: _currentPosition != null,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Center(
                child: _LoadingRouteCard(),
              )
            else if (_error != null)
              _RouteErrorPanel(error: _error!, onRetry: _loadRoute)
            else if (route != null)
              _NavigationBottomSheet(
                route: route,
                mode: _mode,
                onSelectMode: _selectMode,
                destinationName: widget.place.name,
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteIdentity extends StatelessWidget {
  const _RouteIdentity(
      {required this.destinationName, required this.hasLocation});

  final String destinationName;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasLocation ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                color: const Color(0xFF1479D1),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('من موقعك الحالي إلى',
                      style: TextStyle(fontSize: 11, color: Color(0xFF687772))),
                  Text(destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173F38),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationBottomSheet extends StatelessWidget {
  const _NavigationBottomSheet({
    required this.route,
    required this.mode,
    required this.onSelectMode,
    required this.destinationName,
  });

  final RouteOption route;
  final TravelMode mode;
  final ValueChanged<TravelMode> onSelectMode;
  final String destinationName;

  @override
  Widget build(BuildContext context) {
    final steps = route.steps.take(5).toList(growable: false);
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.27,
      maxChildSize: 0.78,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Color(0x330E2924),
                blurRadius: 24,
                offset: Offset(0, -6)),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E0DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('نوع التنقل',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF173F38),
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                _ModeButton(
                  mode: TravelMode.car,
                  selected: mode == TravelMode.car,
                  icon: Icons.directions_car_filled_rounded,
                  label: 'سيارة',
                  onTap: () => onSelectMode(TravelMode.car),
                ),
                const SizedBox(width: 8),
                _ModeButton(
                  mode: TravelMode.foot,
                  selected: mode == TravelMode.foot,
                  icon: Icons.directions_walk_rounded,
                  label: 'مشي',
                  onTap: () => onSelectMode(TravelMode.foot),
                ),
                const SizedBox(width: 8),
                _ModeButton(
                  mode: TravelMode.motorcycle,
                  selected: mode == TravelMode.motorcycle,
                  icon: Icons.two_wheeler_rounded,
                  label: 'دراجة نارية',
                  onTap: () => onSelectMode(TravelMode.motorcycle),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _JourneySummary(route: route, mode: mode),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.route_rounded,
                    color: Color(0xFF1479D1), size: 21),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('تعليمات الطريق',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173F38),
                      )),
                ),
                Text(destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF687772))),
              ],
            ),
            const SizedBox(height: 8),
            if (steps.isEmpty)
              const _InstructionRow(
                icon: Icons.straight_rounded,
                title: 'اتبع المسار المرسوم على الخريطة حتى الوصول.',
                distance: null,
              )
            else ...[
              _InstructionRow(
                icon: Icons.navigation_rounded,
                title: 'انطلق من موقعك الحالي',
                distance: null,
              ),
              ...steps.map(
                (step) => _InstructionRow(
                  icon: _maneuverIcon(step.maneuver),
                  title: _maneuverLabel(step),
                  distance: step.distanceMeters,
                ),
              ),
              _InstructionRow(
                icon: Icons.flag_rounded,
                title: 'وصلت إلى وجهتك',
                distance: null,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _maneuverIcon(String maneuver) => switch (maneuver) {
        'left' || 'slight_left' || 'sharp_left' => Icons.turn_left_rounded,
        'right' || 'slight_right' || 'sharp_right' => Icons.turn_right_rounded,
        'u_turn' => Icons.u_turn_left_rounded,
        'roundabout' => Icons.roundabout_right_rounded,
        'arrive' => Icons.flag_rounded,
        _ => Icons.straight_rounded,
      };

  String _maneuverLabel(RouteStep step) {
    final street = step.streetName == null ? '' : ' باتجاه ${step.streetName}';
    return switch (step.maneuver) {
      'left' || 'slight_left' || 'sharp_left' => 'انعطف يساراً$street',
      'right' || 'slight_right' || 'sharp_right' => 'انعطف يميناً$street',
      'u_turn' => 'استدر للخلف$street',
      'roundabout' => 'تابع عبر الدوار$street',
      'arrive' => 'وصلت إلى وجهتك',
      _ => 'تابع للأمام$street',
    };
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final TravelMode mode;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF173F38) : const Color(0xFF687772);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF173F38) : const Color(0xFFF1F5F3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, size: 21, color: selected ? Colors.white : color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({required this.route, required this.mode});

  final RouteOption route;
  final TravelMode mode;

  @override
  Widget build(BuildContext context) {
    final minutes = (route.durationSeconds / 60).ceil();
    final distance = route.distanceMeters >= 1000
        ? '${(route.distanceMeters / 1000).toStringAsFixed(1)} كم'
        : '${route.distanceMeters.round()} م';
    final duration =
        minutes >= 60 ? '${minutes ~/ 60} س ${minutes % 60} د' : '$minutes د';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _Stat(
              icon: Icons.straighten_rounded,
              label: 'المسافة',
              value: distance),
          const _StatDivider(),
          _Stat(
              icon: Icons.schedule_rounded,
              label: 'الوقت المتوقع',
              value: duration),
          const _StatDivider(),
          _Stat(
              icon: Icons.alt_route_rounded,
              label: 'المنعطفات',
              value: '${route.steps.length}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1479D1)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF173F38),
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF687772))),
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 55,
        color: const Color(0xFFD7E0DD),
      );
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.icon,
    required this.title,
    required this.distance,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final double? distance;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final distanceText = distance == null || distance == 0
        ? null
        : distance! >= 1000
            ? '${(distance! / 1000).toStringAsFixed(1)} كم'
            : '${distance!.round()} م';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isLast ? const Color(0xFFE8F7EF) : const Color(0xFFEAF4FD),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 17,
              color:
                  isLast ? const Color(0xFF138A55) : const Color(0xFF1479D1)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(title,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B403A),
                )),
          ),
        ),
        if (distanceText != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(distanceText,
                style: const TextStyle(fontSize: 11, color: Color(0xFF687772))),
          ),
      ],
    );
  }
}

class _LoadingRouteCard extends StatelessWidget {
  const _LoadingRouteCard();

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text('جارٍ حساب أفضل مسار…',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _RouteErrorPanel extends StatelessWidget {
  const _RouteErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x33152824), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_rounded,
                    color: Color(0xFFD94B4B), size: 34),
                const SizedBox(height: 8),
                Text(error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        height: 1.45, color: Color(0xFF5C2C2C))),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث الموقع والمحاولة مجدداً'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) => const Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(Icons.location_on_rounded, color: Color(0xFFD92D45), size: 50),
          Positioned(
            top: 10,
            child: Icon(Icons.place_rounded, color: Colors.white, size: 18),
          ),
        ],
      );
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1479D1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 8)
            ],
          ),
        ),
      );
}
