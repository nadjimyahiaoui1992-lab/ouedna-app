import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';
import 'live_navigation_controller.dart';
import 'navigation_voice_service.dart';

class LiveNavigationPage extends StatefulWidget {
  const LiveNavigationPage({
    super.key,
    required this.place,
    required this.routingService,
  });

  final Place place;
  final RoutingService routingService;

  @override
  State<LiveNavigationPage> createState() => _LiveNavigationPageState();
}

class _LiveNavigationPageState extends State<LiveNavigationPage> {
  late final LiveNavigationController _navigation;
  late final NavigationVoiceService _voice;
  late final StreamSubscription<NavigationVoiceEvent> _voiceSubscription;
  final MapController _mapController = MapController();
  bool _voiceEnabled = true;
  bool _mapReady = false;
  RouteOption? _lastFittedRoute;

  @override
  void initState() {
    super.initState();
    _voice = NavigationVoiceService();
    _navigation = LiveNavigationController(
      place: widget.place,
      routingService: widget.routingService,
    )..addListener(_onNavigationChanged);
    _voiceSubscription = _navigation.voiceEvents.listen((event) {
      if (_voiceEnabled) _voice.speak(event.message);
    });
    _navigation.prepareRoute();
  }

  void _onNavigationChanged() {
    final position = _navigation.currentPosition;
    final route = _navigation.result?.routes.isNotEmpty == true
        ? _navigation.result!.routes.first
        : null;
    if (_mapReady && route != null && _lastFittedRoute != route) {
      _fitRoute(route);
    } else if (_mapReady && _navigation.isActive && position != null) {
      try {
        _mapController.move(position, 17);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _onMapReady() {
    _mapReady = true;
    final route = _navigation.result?.routes.isNotEmpty == true
        ? _navigation.result!.routes.first
        : null;
    if (route != null) _fitRoute(route);
  }

  void _fitRoute(RouteOption route) {
    if (!_mapReady || route.geometry.length < 2) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.geometry),
          padding: const EdgeInsets.fromLTRB(34, 120, 34, 330),
          maxZoom: 15.5,
        ),
      );
      _lastFittedRoute = route;
    } catch (_) {}
  }

  Future<void> _toggleNavigation() async {
    if (_navigation.isActive) {
      await _navigation.stop();
      await _voice.stop();
      return;
    }
    await _navigation.start();
  }

  Future<void> _toggleVoice() async {
    setState(() => _voiceEnabled = !_voiceEnabled);
    _voice.enabled = _voiceEnabled;
    if (_voiceEnabled) {
      await _voice.speak('تم تفعيل التوجيه الصوتي.');
    } else {
      await _voice.stop();
    }
  }

  @override
  void dispose() {
    _voiceSubscription.cancel();
    _voice.stop();
    _navigation
      ..removeListener(_onNavigationChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude!, widget.place.longitude!);
    final route = _navigation.result?.routes.isNotEmpty == true
        ? _navigation.result!.routes.first
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6F4),
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navigation.isActive ? 'ملاحة حية' : 'الملاحة الذكية',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
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
              tooltip: _voiceEnabled ? 'إيقاف الصوت' : 'تفعيل الصوت',
              onPressed: _toggleVoice,
              icon: Icon(
                _voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
              ),
            ),
            IconButton(
              tooltip: 'تحديث الموقع والمسار',
              onPressed:
                  _navigation.isLoading ? null : _navigation.prepareRoute,
              icon: const Icon(Icons.my_location_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: destination,
                initialZoom: 13,
                onMapReady: _onMapReady,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.ouedna.app',
                ),
                if (route != null && route.geometry.isNotEmpty) ...[
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 12,
                        color: const Color(0x35112D28),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 6,
                        color: _navigation.isRerouting
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF1479D1),
                      ),
                    ],
                  ),
                ],
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination,
                      width: 52,
                      height: 60,
                      child: const _LiveDestinationMarker(),
                    ),
                    if (_navigation.currentPosition != null)
                      Marker(
                        point: _navigation.currentPosition!,
                        width: 56,
                        height: 56,
                        child: _LiveUserMarker(active: _navigation.isActive),
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
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 78),
                    child: _LiveNavigationStatus(
                      isActive: _navigation.isActive,
                      isRerouting: _navigation.isRerouting,
                      voiceEnabled: _voiceEnabled,
                      currentInstruction: route == null
                          ? null
                          : _instructionFor(
                              route.steps.isEmpty
                                  ? null
                                  : route.steps[_navigation.activeStepIndex
                                      .clamp(0, route.steps.length - 1)],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (route != null)
              PositionedDirectional(
                start: 14,
                top: MediaQuery.paddingOf(context).top + 88,
                child: FloatingActionButton.small(
                  heroTag: 'fit-live-route',
                  tooltip: 'عرض المسار كاملاً',
                  onPressed: () => _fitRoute(route),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF173F38),
                  child: const Icon(Icons.fit_screen_rounded),
                ),
              ),
            if (_navigation.isLoading)
              const Center(child: _LiveLoadingCard())
            else if (_navigation.error != null)
              _LiveErrorPanel(
                error: _navigation.error!,
                onRetry: _navigation.prepareRoute,
              )
            else if (route != null)
              _LiveNavigationSheet(
                route: route,
                mode: _navigation.mode,
                isActive: _navigation.isActive,
                isRerouting: _navigation.isRerouting,
                voiceEnabled: _voiceEnabled,
                activeStepIndex: _navigation.activeStepIndex,
                remainingDistanceMeters: _navigation.remainingDistanceMeters,
                remainingDurationSeconds: _navigation.remainingDurationSeconds,
                onSelectMode: _navigation.changeMode,
                onToggleNavigation: _toggleNavigation,
                onToggleVoice: _toggleVoice,
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveNavigationStatus extends StatelessWidget {
  const _LiveNavigationStatus({
    required this.isActive,
    required this.isRerouting,
    required this.voiceEnabled,
    required this.currentInstruction,
  });

  final bool isActive;
  final bool isRerouting;
  final bool voiceEnabled;
  final String? currentInstruction;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE7F7EE)
                      : const Color(0xFFEAF4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRerouting
                      ? Icons.autorenew_rounded
                      : isActive
                          ? Icons.navigation_rounded
                          : Icons.route_rounded,
                  color: isRerouting
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF1479D1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRerouting
                          ? 'جارٍ تحديث المسار…'
                          : isActive
                              ? 'الملاحة الحية مفعّلة'
                              : 'المسار جاهز للانطلاق',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173F38),
                      ),
                    ),
                    Text(
                      currentInstruction ??
                          'اضغط «ابدأ الملاحة» لتفعيل التتبع الحي.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF687772)),
                    ),
                  ],
                ),
              ),
              Icon(
                voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 19,
                color: voiceEnabled
                    ? const Color(0xFF138A55)
                    : const Color(0xFF8A9793),
              ),
            ],
          ),
        ),
      );
}

class _LiveNavigationSheet extends StatelessWidget {
  const _LiveNavigationSheet({
    required this.route,
    required this.mode,
    required this.isActive,
    required this.isRerouting,
    required this.voiceEnabled,
    required this.activeStepIndex,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.onSelectMode,
    required this.onToggleNavigation,
    required this.onToggleVoice,
  });

  final RouteOption route;
  final TravelMode mode;
  final bool isActive;
  final bool isRerouting;
  final bool voiceEnabled;
  final int activeStepIndex;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final ValueChanged<TravelMode> onSelectMode;
  final VoidCallback onToggleNavigation;
  final VoidCallback onToggleVoice;

  @override
  Widget build(BuildContext context) {
    final displayedDistance =
        isActive ? remainingDistanceMeters : route.distanceMeters;
    final displayedDuration =
        isActive ? remainingDurationSeconds : route.durationSeconds;
    final steps = route.steps.take(8).toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: isActive ? 0.33 : 0.29,
      minChildSize: 0.23,
      maxChildSize: 0.72,
      builder: (context, controller) => Container(
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
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E0DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _LiveStats(
              distanceMeters: displayedDistance,
              durationSeconds: displayedDuration,
              turnCount: route.steps.length,
              active: isActive,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onToggleNavigation,
              icon: Icon(isActive
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_fill_rounded),
              label:
                  Text(isActive ? 'إنهاء الملاحة الحية' : 'ابدأ الملاحة الحية'),
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFD94B4B)
                    : const Color(0xFF173F38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleVoice,
                    icon: Icon(voiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded),
                    label: Text(voiceEnabled ? 'الصوت مفعّل' : 'تفعيل الصوت'),
                  ),
                ),
                const SizedBox(width: 8),
                if (isRerouting)
                  const Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 7),
                          Text('تحديث المسار', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      'يتحدث الوقت والمسافة تلقائياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF687772)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 17),
            const Text('نوع التنقل',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF173F38))),
            const SizedBox(height: 9),
            Row(
              children: [
                _LiveModeButton(
                  selected: mode == TravelMode.car,
                  icon: Icons.directions_car_filled_rounded,
                  label: 'سيارة',
                  onTap: () => onSelectMode(TravelMode.car),
                ),
                const SizedBox(width: 8),
                _LiveModeButton(
                  selected: mode == TravelMode.foot,
                  icon: Icons.directions_walk_rounded,
                  label: 'مشي',
                  onTap: () => onSelectMode(TravelMode.foot),
                ),
                const SizedBox(width: 8),
                _LiveModeButton(
                  selected: mode == TravelMode.motorcycle,
                  icon: Icons.two_wheeler_rounded,
                  label: 'دراجة نارية',
                  onTap: () => onSelectMode(TravelMode.motorcycle),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded,
                    color: Color(0xFF1479D1), size: 20),
                SizedBox(width: 8),
                Text('تعليمات الطريق',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF173F38))),
              ],
            ),
            const SizedBox(height: 8),
            if (steps.isEmpty)
              const _LiveInstructionRow(
                icon: Icons.straight_rounded,
                title: 'اتبع المسار المرسوم على الخريطة حتى الوصول.',
                distance: null,
                highlighted: false,
              )
            else ...[
              const _LiveInstructionRow(
                icon: Icons.navigation_rounded,
                title: 'انطلق من موقعك الحالي',
                distance: null,
                highlighted: false,
              ),
              ...steps.indexed.map(
                (entry) => _LiveInstructionRow(
                  icon: _maneuverIcon(entry.$2.maneuver),
                  title: _instructionFor(entry.$2),
                  distance: entry.$2.distanceMeters,
                  highlighted: isActive && entry.$1 == activeStepIndex,
                ),
              ),
              const _LiveInstructionRow(
                icon: Icons.flag_rounded,
                title: 'وصلت إلى وجهتك',
                distance: null,
                highlighted: false,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveStats extends StatelessWidget {
  const _LiveStats({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.turnCount,
    required this.active,
  });

  final double distanceMeters;
  final double durationSeconds;
  final int turnCount;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE9F7EF) : const Color(0xFFF2F7F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _LiveStat(
                icon: Icons.straighten_rounded,
                label: active ? 'المتبقي' : 'المسافة',
                value: _distanceText(distanceMeters)),
            const _LiveStatDivider(),
            _LiveStat(
                icon: Icons.schedule_rounded,
                label: active ? 'وقت الوصول' : 'الوقت المتوقع',
                value: _durationText(durationSeconds)),
            const _LiveStatDivider(),
            _LiveStat(
                icon: Icons.alt_route_rounded,
                label: 'المنعطفات',
                value: '$turnCount'),
          ],
        ),
      );
}

class _LiveStat extends StatelessWidget {
  const _LiveStat(
      {required this.icon, required this.label, required this.value});

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
                    fontWeight: FontWeight.w900, color: Color(0xFF173F38))),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF687772))),
          ],
        ),
      );
}

class _LiveStatDivider extends StatelessWidget {
  const _LiveStatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 55, color: const Color(0xFFD7E0DD));
}

class _LiveModeButton extends StatelessWidget {
  const _LiveModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFF173F38) : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? Colors.white : const Color(0xFF687772)),
                const SizedBox(height: 4),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? Colors.white : const Color(0xFF687772))),
              ],
            ),
          ),
        ),
      );
}

class _LiveInstructionRow extends StatelessWidget {
  const _LiveInstructionRow({
    required this.icon,
    required this.title,
    required this.distance,
    required this.highlighted,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final double? distance;
  final bool highlighted;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFE9F4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:
                    isLast ? const Color(0xFFE8F7EF) : const Color(0xFFEAF4FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 17,
                  color: isLast
                      ? const Color(0xFF138A55)
                      : const Color(0xFF1479D1)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight:
                            highlighted ? FontWeight.w900 : FontWeight.w600,
                        color: const Color(0xFF2B403A))),
              ),
            ),
            if (distance != null && distance! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(_distanceText(distance!),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF687772))),
              ),
          ],
        ),
      );
}

class _LiveLoadingCard extends StatelessWidget {
  const _LiveLoadingCard();

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
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(width: 12),
              Text('جارٍ تحديد موقعك وحساب المسار…',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _LiveErrorPanel extends StatelessWidget {
  const _LiveErrorPanel({required this.error, required this.onRetry});

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
                BoxShadow(color: Color(0x33152824), blurRadius: 20)
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

class _LiveDestinationMarker extends StatelessWidget {
  const _LiveDestinationMarker();

  @override
  Widget build(BuildContext context) => const Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(Icons.location_on_rounded, color: Color(0xFFD92D45), size: 52),
          Positioned(
              top: 11,
              child: Icon(Icons.place_rounded, color: Colors.white, size: 18)),
        ],
      );
}

class _LiveUserMarker extends StatelessWidget {
  const _LiveUserMarker({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: active ? 30 : 24,
          height: active ? 30 : 24,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF138A55) : const Color(0xFF1479D1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 8)
            ],
          ),
          child: active
              ? const Icon(Icons.navigation_rounded,
                  color: Colors.white, size: 15)
              : null,
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

String _instructionFor(RouteStep? step) {
  if (step == null) return 'اتبع المسار المرسوم على الخريطة.';
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

String _distanceText(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} كم'
    : '${meters.round()} م';

String _durationText(double seconds) {
  final minutes = (seconds / 60).ceil();
  return minutes >= 60 ? '${minutes ~/ 60} س ${minutes % 60} د' : '$minutes د';
}
