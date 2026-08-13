import 'package:cached_network_image/cached_network_image.dart';
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
  final _placePageController = PageController(viewportFraction: .87);
  late Future<List<Place>> _future;
  _MapLayer _layer = _MapLayer.standard;
  String? _category;
  LatLng? _myLocation;
  Place? _selectedPlace;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _placePageController.dispose();
    super.dispose();
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

  void _selectPlace(Place place, List<Place> visiblePlaces, {bool syncCarousel = true}) {
    if (!place.hasCoordinates) return;
    setState(() => _selectedPlace = place);
    _mapController.move(LatLng(place.latitude!, place.longitude!), 15.2);
    if (syncCarousel && _placePageController.hasClients) {
      final index = visiblePlaces.indexWhere((item) => item.id == place.id);
      if (index >= 0) {
        _placePageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _openPlace(Place place) {
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
  }

  void _selectCategory(String? category) {
    setState(() {
      _category = category;
      if (_selectedPlace != null && category != null && _selectedPlace!.category != category) {
        _selectedPlace = null;
      }
    });
    if (_placePageController.hasClients) _placePageController.jumpToPage(0);
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
            final visiblePlaces = _category == null
                ? allPlaces
                : allPlaces.where((place) => place.category == _category).toList(growable: false);
            final selected = visiblePlaces.any((item) => item.id == _selectedPlace?.id)
                ? _selectedPlace
                : (visiblePlaces.isEmpty ? null : visiblePlaces.first);

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
                        ...visiblePlaces.map(
                          (place) => _placeMarker(
                            place,
                            selected: place.id == selected?.id,
                            onTap: () => _selectPlace(place, visiblePlaces),
                          ),
                        ),
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
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      children: [
                        _MapHeader(
                          count: visiblePlaces.length,
                          layer: _layer,
                          onLayerChanged: (layer) => setState(() => _layer = layer),
                          onRefresh: _reload,
                        ),
                        const SizedBox(height: 10),
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
                                    onTap: () => _selectCategory(null),
                                  ),
                                  ...categories.map(
                                    (category) => _CategoryChip(
                                      label: category,
                                      selected: _category == category,
                                      onTap: () => _selectCategory(category),
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
                              const SizedBox(height: 8),
                              _MapControl(
                                icon: Icons.center_focus_strong_rounded,
                                tooltip: 'مركز الخريطة',
                                onTap: () => _mapController.move(_elOued, 11.5),
                              ),
                            ],
                          ),
                        ),
                        if (visiblePlaces.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 150,
                            child: _PlaceCarousel(
                              controller: _placePageController,
                              places: visiblePlaces,
                              selectedId: selected?.id,
                              onPageChanged: (index) => _selectPlace(
                                visiblePlaces[index],
                                visiblePlaces,
                                syncCarousel: false,
                              ),
                              onOpen: _openPlace,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
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

  Marker _placeMarker(Place place, {required bool selected, required VoidCallback onTap}) => Marker(
        point: LatLng(place.latitude!, place.longitude!),
        width: selected ? 76 : 66,
        height: selected ? 88 : 78,
        alignment: Alignment.topCenter,
        child: Semantics(
          button: true,
          label: 'عرض ${place.name}',
          child: GestureDetector(
            onTap: onTap,
            child: _PlaceImageMarker(place: place, selected: selected),
          ),
        ),
      );
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
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          backgroundColor: Colors.white.withOpacity(.95),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
        color: Colors.white,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon),
        ),
      );
}

class _PlaceImageMarker extends StatelessWidget {
  const _PlaceImageMarker({required this.place, required this.selected});
  final Place place;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 64.0 : 56.0;
    const green = Color(0xFF174D42);
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: size * .52,
          child: Icon(
            Icons.location_on_rounded,
            color: green,
            size: selected ? 70 : 62,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 7, offset: Offset(0, 2))],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: green, width: selected ? 4 : 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: ClipOval(child: _PlaceImage(imageUrl: place.imageUrl, iconSize: selected ? 25 : 22)),
        ),
      ],
    );
  }
}

class _PlaceCarousel extends StatelessWidget {
  const _PlaceCarousel({
    required this.controller,
    required this.places,
    required this.selectedId,
    required this.onPageChanged,
    required this.onOpen,
  });

  final PageController controller;
  final List<Place> places;
  final int? selectedId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Place> onOpen;

  @override
  Widget build(BuildContext context) => PageView.builder(
        controller: controller,
        itemCount: places.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final place = places[index];
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsetsDirectional.only(end: 8, top: place.id == selectedId ? 0 : 7, bottom: place.id == selectedId ? 0 : 7),
            child: _PlacePreviewCard(place: place, selected: place.id == selectedId, onTap: () => onOpen(place)),
          );
        },
      );
}

class _PlacePreviewCard extends StatelessWidget {
  const _PlacePreviewCard({required this.place, required this.selected, required this.onTap});
  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: selected ? 7 : 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _PlaceImage(imageUrl: place.imageUrl, iconSize: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(height: 5),
                        Text(place.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: Colors.black54),
                            const SizedBox(width: 3),
                            Expanded(child: Text(place.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.chevron_left_rounded),
              ],
            ),
          ),
        ),
      );
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({required this.imageUrl, required this.iconSize});
  final String? imageUrl;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(child: Icon(Icons.landscape_outlined, size: iconSize, color: Theme.of(context).colorScheme.primary)),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(child: Icon(Icons.image_not_supported_outlined, size: iconSize, color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.blue.withOpacity(.25), shape: BoxShape.circle),
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
          child: Text('لا توجد إحداثيات منشورة حالياً. ستظهر المعالم هنا بمجرد اعتمادها من لوحة الإدارة.', textAlign: TextAlign.center),
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
