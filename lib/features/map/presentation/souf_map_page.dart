import 'dart:math' as math;

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
import '../../places/presentation/place_details_page.dart';

class SoufMapPage extends StatefulWidget {
  const SoufMapPage({
    super.key,
    required this.repository,
    required this.favorites,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;

  @override
  State<SoufMapPage> createState() => _SoufMapPageState();
}

class _SoufMapPageState extends State<SoufMapPage> {
  final _mapController = MapController();
  final _locationService = LocationService();
  List<Place> _places = const [];
  List<String> _categories = const [];
  String? _category;
  Position? _position;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  List<Place> get _visiblePlaces => _category == null
      ? _places
      : _places
          .where((place) => place.category == _category)
          .toList(growable: false);

  Future<void> _findMyLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد موقعك الآن.')));
    }
  }

  void _openDetails(Place place) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: widget.repository,
            favorites: widget.favorites,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: _MapSkeleton());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final markers = _visiblePlaces
        .map(
          (place) => Marker(
            point: LatLng(place.latitude!, place.longitude!),
            width: 48,
            height: 48,
            child: IconButton.filled(
              tooltip: place.name,
              style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF193F38)),
              onPressed: () => _showPlaceSheet(place),
              icon: const Icon(Icons.location_on, color: Color(0xFFE5B65A)),
            ),
          ),
        )
        .toList(growable: false);
    if (_position != null) {
      markers.add(
        Marker(
          point: LatLng(_position!.latitude, _position!.longitude),
          width: 42,
          height: 42,
          child:
              const Icon(Icons.my_location, color: Color(0xFFD9A441), size: 34),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
                initialCenter: LatLng(33.367, 6.867), initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.souf360.app',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 48,
                  size: const Size(46, 46),
                  markers: markers,
                  builder: (context, clusteredMarkers) => DecoratedBox(
                    decoration: const BoxDecoration(
                        color: Color(0xFF193F38), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${clusteredMarkers.length}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 14,
            left: 14,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                    (category) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.repository is OfflineAwarePlaceRepository &&
              (widget.repository as OfflineAwarePlaceRepository)
                  .isUsingCachedData)
            const Positioned(
              top: 66,
              right: 14,
              left: 14,
              child: OfflineCatalogueNotice(),
            ),
          Positioned(
            left: 16,
            bottom: 22,
            child: FloatingActionButton.small(
              heroTag: 'my-location',
              tooltip: 'موقعي الحالي',
              onPressed: _findMyLocation,
              child: const Icon(Icons.my_location_outlined),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 22,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              tooltip: 'إظهار جميع المعالم',
              onPressed: _fitAllMarkers,
              child: const Icon(Icons.zoom_out_map_outlined),
            ),
          ),
        ],
      ),
    );
  }

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
      math.max(11, 13 - math.log(places.length) / math.ln2),
    );
  }

  void _showPlaceSheet(Place place) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.category,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(place.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(place.locationLabel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openDetails(place);
                },
                icon: const Icon(Icons.arrow_back_outlined),
                label: const Text('عرض التفاصيل'),
              ),
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
