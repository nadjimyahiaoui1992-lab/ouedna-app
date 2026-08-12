import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../../core/widgets/offline_catalogue_notice.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../routing/domain/routing_service.dart';
import '../../places/presentation/place_details_page.dart';

class SoufMapPage extends StatefulWidget {
  const SoufMapPage({
    super.key,
    required this.repository,
    required this.favorites,
    this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<SoufMapPage> createState() => _SoufMapPageState();
}

class _SoufMapPageState extends State<SoufMapPage> {
  static const _elOued = LatLng(33.367, 6.867);
  static const _nearbyRadiusMeters = 20000.0;

  final _mapController = MapController();
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  List<Place> _places = const [];
  List<String> _categories = const [];
  String? _category;
  String _query = '';
  Position? _position;
  String? _error;
  bool _loading = true;
  bool _nearbyOnly = false;
  bool _satelliteMode = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = widget.repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _error = 'تعذر الاتصال بمصدر بيانات Souf360.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        repository.getPublishedPlaces(),
        repository.getPublishedCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _places = (results[0] as List<Place>)
            .where((place) => place.hasCoordinates)
            .toList(growable: false);
        _categories = results[1] as List<String>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'تعذر تحميل مواقع المعالم. تحقق من اتصال الإنترنت ثم أعد المحاولة.';
      });
    }
  }

  List<Place> get _visiblePlaces {
    final normalized = _normalize(_query);
    final filtered = _places.where((place) {
      if (_category != null && place.category != _category) return false;
      if (normalized.isNotEmpty && !_matches(place, normalized)) return false;
      if (_nearbyOnly &&
          (_position == null || _distanceMeters(place) > _nearbyRadiusMeters)) {
        return false;
      }
      return true;
    }).toList(growable: false);
    if (_position != null) {
      filtered.sort((a, b) => _distanceMeters(a).compareTo(_distanceMeters(b)));
    }
    return filtered;
  }

  bool _matches(Place place, String normalizedQuery) {
    final searchable = [
      place.name,
      place.description,
      place.category,
      place.subCategory,
      place.address,
      place.district,
      place.municipality,
    ].whereType<String>().join(' ');
    return _normalize(searchable).contains(normalizedQuery);
  }

  String _normalize(String value) => value.toLowerCase().trim();

  double _distanceMeters(Place place) {
    final position = _position;
    if (position == null || !place.hasCoordinates) return double.infinity;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.latitude!,
      place.longitude!,
    );
  }

  String? _distanceLabel(Place place) {
    final distance = _distanceMeters(place);
    if (!distance.isFinite) return null;
    return distance < 1000
        ? '${distance.round()} م'
        : '${(distance / 1000).toStringAsFixed(1)} كم';
  }

  Future<void> _findMyLocation({bool enableNearby = false}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _isLocating = false;
        if (enableNearby) _nearbyOnly = true;
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('تم تحديد موقعك. يمكنك الآن استكشاف الأماكن القريبة.')),
      );
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      _showLocationRecovery(error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك الآن.')),
      );
    }
  }

  Future<void> _toggleNearby() async {
    if (_nearbyOnly) {
      setState(() => _nearbyOnly = false);
      return;
    }
    await _findMyLocation(enableNearby: true);
  }

  void _showLocationRecovery(LocationException error) {
    final recoveryLabel = error.recoveryLabel;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        duration: const Duration(seconds: 8),
        action: recoveryLabel == null
            ? null
            : SnackBarAction(
                label: recoveryLabel,
                onPressed: () {
                  switch (error.issue) {
                    case LocationIssue.serviceDisabled:
                      _locationService.openDeviceLocationSettings();
                      break;
                    case LocationIssue.permissionDeniedForever:
                      _locationService.openApplicationSettings();
                      break;
                    default:
                      break;
                  }
                },
              ),
      ),
    );
  }

  void _openDetails(Place place) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: widget.repository,
            favorites: widget.favorites,
            routingService: widget.routingService,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: _MapSkeleton());
    if (_error != null) return _MapError(message: _error!, onRetry: _load);

    final places = _visiblePlaces;
    final markers = [
      ...places.map(_placeMarker),
      if (_position != null) _myLocationMarker(),
    ];

    return SafeArea(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _elOued, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: _satelliteMode
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.souf360.app',
                maxNativeZoom: _satelliteMode ? 19 : 19,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 52,
                  size: const Size(48, 48),
                  markers: markers,
                  builder: (context, clusteredMarkers) =>
                      _ClusterMarker(count: clusteredMarkers.length),
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 14,
            left: 14,
            child: Row(
              children: [
                Expanded(
                  child: _MapHeader(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _satelliteMode
                      ? 'الخريطة العادية'
                      : 'عرض الأقمار الصناعية',
                  child: IconButton.filled(
                    onPressed: () =>
                        setState(() => _satelliteMode = !_satelliteMode),
                    icon: Icon(_satelliteMode
                        ? Icons.map_outlined
                        : Icons.satellite_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 78,
            right: 14,
            left: 14,
            child: _FilterStrip(
              categories: _categories,
              selectedCategory: _category,
              nearbyOnly: _nearbyOnly,
              onSelectCategory: (category) =>
                  setState(() => _category = category),
              onToggleNearby: _toggleNearby,
            ),
          ),
          if (widget.repository is OfflineAwarePlaceRepository &&
              (widget.repository as OfflineAwarePlaceRepository)
                  .isUsingCachedData)
            const Positioned(
              top: 128,
              right: 14,
              left: 14,
              child: OfflineCatalogueNotice(),
            ),
          if (places.isEmpty)
            Positioned(
              right: 30,
              left: 30,
              bottom: 118,
              child: _NoMapResults(
                nearbyOnly: _nearbyOnly,
                onReset: () => setState(() {
                  _nearbyOnly = false;
                  _category = null;
                  _query = '';
                  _searchController.clear();
                }),
              ),
            ),
          PositionedDirectional(
            start: 16,
            bottom: 22,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'my-location',
                  tooltip: 'موقعي الحالي',
                  onPressed: _isLocating ? null : _findMyLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_outlined),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  tooltip: 'إظهار المعالم',
                  onPressed: _fitAllMarkers,
                  child: const Icon(Icons.zoom_out_map_outlined),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 24,
            child: _MapCount(count: places.length),
          ),
          Positioned(
            right: 14,
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(.88),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                child: Text(
                  _satelliteMode
                      ? 'صور الأقمار الصناعية © Esri'
                      : '© OpenStreetMap',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _placeMarker(Place place) => Marker(
        point: LatLng(place.latitude!, place.longitude!),
        width: 56,
        height: 64,
        child: Semantics(
          button: true,
          label: 'فتح ${place.name}',
          child: GestureDetector(
            onTap: () => _showPlaceSheet(place),
            child: _PlaceMarker(place: place),
          ),
        ),
      );

  Marker _myLocationMarker() => Marker(
        point: LatLng(_position!.latitude, _position!.longitude),
        width: 44,
        height: 44,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE5B65A),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Icon(Icons.navigation_rounded, color: Color(0xFF102D28)),
        ),
      );

  void _fitAllMarkers() {
    final places = _visiblePlaces;
    if (places.isEmpty) return;
    if (places.length == 1) {
      _mapController.move(
          LatLng(places.first.latitude!, places.first.longitude!), 14);
      return;
    }
    final latitudes = places.map((place) => place.latitude!).toList();
    final longitudes = places.map((place) => place.longitude!).toList();
    _mapController.move(
      LatLng(
        latitudes.reduce((a, b) => a + b) / latitudes.length,
        longitudes.reduce((a, b) => a + b) / longitudes.length,
      ),
      math.max(10, 13 - math.log(places.length) / math.ln2),
    );
  }

  void _showPlaceSheet(Place place) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _PlaceSheet(
          place: place,
          distanceLabel: _distanceLabel(place),
          onDetails: () {
            Navigator.pop(context);
            _openDetails(place);
          },
        ),
      );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 3,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث عن مكان على الخريطة',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear, icon: const Icon(Icons.close_rounded)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      );
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.categories,
    required this.selectedCategory,
    required this.nearbyOnly,
    required this.onSelectCategory,
    required this.onToggleNearby,
  });

  final List<String> categories;
  final String? selectedCategory;
  final bool nearbyOnly;
  final ValueChanged<String?> onSelectCategory;
  final VoidCallback onToggleNearby;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              avatar: Icon(
                  nearbyOnly ? Icons.near_me_rounded : Icons.near_me_outlined,
                  size: 18),
              label: const Text('قريب مني'),
              selected: nearbyOnly,
              onSelected: (_) => onToggleNearby(),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('الكل'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelectCategory(null),
            ),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) => onSelectCategory(category),
                ),
              ),
            ),
          ],
        ),
      );
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 38,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                  width: 16, height: 16, color: const Color(0xFF193F38)),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Color(0xFF193F38),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
              ],
            ),
            child: ClipOval(
              child: place.imageUrl == null
                  ? const ColoredBox(
                      color: Color(0xFFE5B65A),
                      child:
                          Icon(Icons.place_rounded, color: Color(0xFF193F38)),
                    )
                  : CachedNetworkImage(
                      imageUrl: place.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE5B65A),
                        child:
                            Icon(Icons.place_rounded, color: Color(0xFF193F38)),
                      ),
                    ),
            ),
          ),
        ],
      );
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF193F38),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Center(
          child: Text('$count',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      );
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({
    required this.place,
    required this.distanceLabel,
    required this.onDetails,
  });

  final Place place;
  final String? distanceLabel;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: place.imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFE5B65A),
                            child: Icon(Icons.landscape_outlined))
                        : CachedNetworkImage(
                            imageUrl: place.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.category,
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (distanceLabel != null || place.rating != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          children: [
                            if (distanceLabel != null)
                              Text('يبعد $distanceLabel'),
                            if (place.rating != null)
                              Text('★ ${place.rating!.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      color: Color(0xFFD9A441))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('عرض التفاصيل'),
              ),
            ),
          ],
        ),
      );
}

class _MapCount extends StatelessWidget {
  const _MapCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text('$count مكان',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}

class _NoMapResults extends StatelessWidget {
  const _NoMapResults({required this.nearbyOnly, required this.onReset});
  final bool nearbyOnly;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 34),
              const SizedBox(height: 8),
              Text(
                nearbyOnly
                    ? 'لا توجد أماكن منشورة قريبة منك حالياً.'
                    : 'لا توجد نتائج مطابقة على الخريطة.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                  onPressed: onReset, child: const Text('إظهار كل المعالم')),
            ],
          ),
        ),
      );
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: const Center(child: Icon(Icons.map_outlined, size: 56)),
      );
}
