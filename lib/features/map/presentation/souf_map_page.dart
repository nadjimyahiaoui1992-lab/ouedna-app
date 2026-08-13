import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_service.dart';

class SoufMapPage extends StatefulWidget {
  const SoufMapPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<SoufMapPage> createState() => _SoufMapPageState();
}

enum _MapLayer { standard, satellite }

class _SoufMapPageState extends State<SoufMapPage> {
  static const _elOued = LatLng(33.3683, 6.8674);
  final _mapController = MapController();
  final _locationService = LocationService();
  late Future<List<Place>> _future;
  _MapLayer _layer = _MapLayer.standard;
  String? _category;
  LatLng? _myLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Place>> _load() =>
      widget.repository?.getPublishedPlaces() ?? Future.value(const <Place>[]);

  void _reload() => setState(() => _future = _load());

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final Position position = await _locationService.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _myLocation = point);
      _mapController.move(point, 15);
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك الآن.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<List<Place>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _MapError(onRetry: _reload);
            final allPlaces = (snapshot.data ?? const <Place>[])
                .where((place) => place.hasCoordinates)
                .toList(growable: false);
            final categories = allPlaces.map((item) => item.category).toSet().toList()..sort();
            final places = _category == null
                ? allPlaces
                : allPlaces.where((place) => place.category == _category).toList(growable: false);
            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: allPlaces.isEmpty
                        ? _elOued
                        : LatLng(allPlaces.first.latitude!, allPlaces.first.longitude!),
                    initialZoom: allPlaces.isEmpty ? 11.5 : 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _layer == _MapLayer.standard
                          ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                          : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.ouedna.app',
                    ),
                    if (_layer == _MapLayer.satellite)
                      TileLayer(
                        urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.ouedna.app',
                      ),
                    MarkerLayer(
                      markers: [
                        ...places.map(_placeMarker),
                        if (_myLocation != null)
                          Marker(
                            point: _myLocation!,
                            width: 50,
                            height: 50,
                            child: const _MyLocationMarker(),
                          ),
                      ],
                    ),
                  ],
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Column(
                      children: [
                        _MapHeader(
                          count: places.length,
                          layer: _layer,
                          onLayerChanged: (layer) => setState(() => _layer = layer),
                          onRefresh: _reload,
                        ),
                        const SizedBox(height: 12),
                        if (categories.isNotEmpty)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              height: 42,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _CategoryChip(
                                    label: 'الكل',
                                    selected: _category == null,
                                    onTap: () => setState(() => _category = null),
                                  ),
                                  ...categories.map(
                                    (category) => _CategoryChip(
                                      label: category,
                                      selected: _category == category,
                                      onTap: () => setState(() => _category = category),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _MapControl(
                                icon: _locating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                                tooltip: 'موقعي الحالي',
                                onTap: _locating ? null : _goToMyLocation,
                              ),
                              const SizedBox(height: 10),
                              _MapControl(
                                icon: Icons.center_focus_strong_rounded,
                                tooltip: 'مركز الخريطة',
                                onTap: () => _mapController.move(_elOued, 11.5),
                              ),
                            ],
                          ),
                        ),
                        if (places.isEmpty) ...[
                          const SizedBox(height: 12),
                          const _MapEmptyNotice(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Marker _placeMarker(Place place) => Marker(
        point: LatLng(place.latitude!, place.longitude!),
        width: 58,
        height: 66,
        child: Semantics(
          button: true,
          label: place.name,
          child: GestureDetector(
            onTap: () => _showPlace(place),
            child: const Icon(Icons.location_on_rounded,
                color: Color(0xFFB63D32), size: 48, shadows: [Shadow(color: Colors.black38, blurRadius: 7)]),
          ),
        ),
      );

  void _showPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.place_outlined),
                ),
                title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${place.category} · ${place.locationLabel}'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailsPage(
                          place: place,
                          repository: widget.repository,
                          favorites: widget.favorites,
                          routingService: widget.routingService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('عرض التفاصيل داخل وادنا'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.count, required this.layer, required this.onLayerChanged, required this.onRefresh});
  final int count;
  final _MapLayer layer;
  final ValueChanged<_MapLayer> onLayerChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.map_outlined)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('خريطة وادنا', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('$count معلم منشور', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton<_MapLayer>(
                tooltip: 'طبقة الخريطة',
                initialValue: layer,
                onSelected: onLayerChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _MapLayer.standard, child: Text('الخريطة العادية')),
                  PopupMenuItem(value: _MapLayer.satellite, child: Text('صور القمر الصناعي')),
                ],
                icon: Icon(layer == _MapLayer.standard ? Icons.layers_outlined : Icons.satellite_alt_outlined),
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          backgroundColor: Colors.white.withOpacity(.94),
        ),
      );
}

class _MapControl extends StatelessWidget {
  const _MapControl({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 4,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon),
        ),
      );
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(.25),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(7),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: SizedBox.expand(),
        ),
      );
}

class _MapEmptyNotice extends StatelessWidget {
  const _MapEmptyNotice();
  @override
  Widget build(BuildContext context) => Card(
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            'لا توجد إحداثيات منشورة حالياً. ستظهر المعالم هنا بمجرد اعتمادها من لوحة الإدارة.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _MapError extends StatelessWidget {
  const _MapError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تعذر تحميل الخريطة — إعادة المحاولة'),
        ),
      );
}
