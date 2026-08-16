import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/ouedna_localization.dart';
import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../routing/domain/routing_service.dart';
import '../../routing/presentation/live_navigation_page.dart';
import '../domain/entities/place.dart';
import '../domain/repositories/place_repository.dart';
import 'place_details_page.dart';
import 'widgets/place_card.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();
  String? _category;
  LatLng? _myLocation;
  bool _locating = false;
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PlacesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Place>> _load() =>
      widget.repository?.getPublishedPlaces(
        query: _searchController.text.trim(),
      ) ??
      Future.value(const <Place>[]);

  void _reload() => setState(() => _future = _load());

  Future<void> _loadUserLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final Position position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك الآن.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _distanceLabel(Place place) {
    final location = _myLocation;
    if (location == null || !place.hasCoordinates) return null;
    final meters = const Distance().as(
      LengthUnit.Meter,
      location,
      LatLng(place.latitude!, place.longitude!),
    );
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
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

  void _openNavigation(Place place) {
    final routingService = widget.routingService;
    if (routingService == null || !place.hasCoordinates) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveNavigationPage(
          place: place,
          routingService: routingService,
        ),
      ),
    );
  }

  Future<void> _sharePlace(Place place) async {
    await Share.share(
      '${place.name}\n${place.locationLabel}\n\nhttps://ouedna.vercel.app/place/${place.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = OuednaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('places')),
        actions: [
          IconButton(
            onPressed: _locating ? null : _loadUserLocation,
            tooltip: strings.text('my_location'),
            icon: Icon(
              _locating
                  ? Icons.hourglass_top_rounded
                  : Icons.my_location_rounded,
            ),
          ),
          IconButton(
            onPressed: _reload,
            tooltip: strings.text('refresh'),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                labelText: strings.text('search_place'),
                hintText: 'اسم، تصنيف، منطقة أو وصف',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: strings.text('refresh'),
                  onPressed: _reload,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Place>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return _ErrorState(onRetry: _reload);

                final sourcePlaces = snapshot.data ?? const <Place>[];
                final categories = sourcePlaces
                    .map((place) => place.category)
                    .where((category) => category.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                final places = sourcePlaces
                    .where(
                      (place) =>
                          _category == null || place.category == _category,
                    )
                    .toList(growable: false);
                if (places.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        strings.text('no_matching_places'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (categories.isNotEmpty)
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ChoiceChip(
                              label: Text(strings.text('all')),
                              selected: _category == null,
                              onSelected: (_) =>
                                  setState(() => _category = null),
                            ),
                            ...categories.map(
                              (category) => Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                child: ChoiceChip(
                                  label: AutoTranslatedText(category),
                                  selected: _category == category,
                                  onSelected: (_) => setState(
                                    () => _category = category,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                          itemCount: places.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return PlaceCard(
                              place: place,
                              favorites: widget.favorites,
                              distanceLabel: _distanceLabel(place),
                              onNavigate: widget.routingService == null
                                  ? null
                                  : () => _openNavigation(place),
                              onShare: () => _sharePlace(place),
                              onTap: () => _openPlace(place),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = OuednaStrings.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(strings.text('places_load_error')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(strings.text('retry')),
          ),
        ],
      ),
    );
  }
}
