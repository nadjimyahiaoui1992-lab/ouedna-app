import 'dart:ui' as ui;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/ouedna_localization.dart';
import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_service.dart';
import '../../routing/presentation/live_navigation_page.dart';

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
  final _placePageController = PageController(viewportFraction: .88);

  late Future<List<Place>> _future;
  StreamSubscription<void>? _placesSubscription;
  _MapLayer _layer = _MapLayer.standard;
  String? _category;
  LatLng? _myLocation;
  Place? _selectedPlace;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _placesSubscription = widget.repository?.watchPublishedPlaces().listen((_) {
      if (!mounted) return;
      _reload();
    });
  }

  @override
  void dispose() {
    _placesSubscription?.cancel();
    _placePageController.dispose();
    super.dispose();
  }

  Future<List<Place>> _load() =>
      widget.repository?.getPublishedPlaces() ?? Future.value(const <Place>[]);

  void _reload() {
    if (!mounted) return;
    setState(() {
      _selectedPlace = null;
      _future = _load();
    });
  }

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

  void _selectPlace(
    Place place,
    List<Place> visiblePlaces, {
    bool syncCarousel = true,
  }) {
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

  void _dismissPlaceCard() => setState(() => _selectedPlace = null);

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
    if (routingService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خدمة الملاحة غير جاهزة حالياً.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveNavigationPage(
          place: place,
          routingService: routingService,
        ),
      ),
    );
  }

  void _selectCategory(String? category) {
    setState(() {
      _category = category;
      if (_selectedPlace != null &&
          (category != null && _selectedPlace!.category != category)) {
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
            final categories =
                allPlaces.map((item) => item.category).toSet().toList()..sort();
            final visiblePlaces = _category == null
                ? allPlaces
                : allPlaces
                    .where((place) => place.category == _category)
                    .toList(growable: false);
            final selectedPlace = visiblePlaces.any(
              (item) => item.id == _selectedPlace?.id,
            )
                ? _selectedPlace
                : null;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: allPlaces.isEmpty
                        ? _elOued
                        : LatLng(allPlaces.first.latitude!,
                            allPlaces.first.longitude!),
                    initialZoom: allPlaces.isEmpty ? 11.5 : 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _layer == _MapLayer.standard
                          ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                          : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.ouedna.app.v2',
                    ),
                    if (_layer == _MapLayer.satellite)
                      TileLayer(
                        urlTemplate:
                            'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.ouedna.app.v2',
                      ),
                    MarkerLayer(
                      markers: [
                        ...visiblePlaces.map(
                          (place) => _placeMarker(
                            place,
                            selected: place.id == selectedPlace?.id,
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
                          onLayerChanged: (layer) =>
                              setState(() => _layer = layer),
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
                                    label:
                                        OuednaStrings.of(context).text('all'),
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
                                icon: _locating
                                    ? Icons.hourglass_top_rounded
                                    : Icons.my_location_rounded,
                                tooltip: OuednaStrings.of(context)
                                    .text('my_location'),
                                onTap: _locating ? null : _goToMyLocation,
                              ),
                              const SizedBox(height: 8),
                              _MapControl(
                                icon: Icons.center_focus_strong_rounded,
                                tooltip: OuednaStrings.of(context)
                                    .text('map_center'),
                                onTap: () => _mapController.move(_elOued, 11.5),
                              ),
                            ],
                          ),
                        ),
                        if (selectedPlace != null) ...[
                          const SizedBox(height: 10),
                          _MapStartNavigationButton(
                            placeName: selectedPlace.name,
                            onTap: () => _openNavigation(selectedPlace),
                          ),
                        ],
                        if (visiblePlaces.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 118,
                            child: _PlaceCarousel(
                              controller: _placePageController,
                              places: visiblePlaces,
                              selectedId: selectedPlace?.id,
                              onPageChanged: (index) => _selectPlace(
                                visiblePlaces[index],
                                visiblePlaces,
                                syncCarousel: false,
                              ),
                              onSelect: (place) =>
                                  _selectPlace(place, visiblePlaces),
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
                if (selectedPlace != null)
                  PositionedDirectional(
                    start: 16,
                    end: 16,
                    bottom: 154,
                    child: _PlacePopupCard(
                      place: selectedPlace,
                      onDismiss: _dismissPlaceCard,
                      onDetails: () => _openPlace(selectedPlace),
                      onNavigate: () => _openNavigation(selectedPlace),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  Marker _placeMarker(
    Place place, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final width = selected ? 82.0 : 72.0;
    final height = selected ? 106.0 : 94.0;
    return Marker(
      point: LatLng(place.latitude!, place.longitude!),
      width: width,
      height: height,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        button: true,
        label: 'عرض ${place.name}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _PlaceImageMarker(
            place: place,
            selected: selected,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }
}

class _MapStartNavigationButton extends StatelessWidget {
  const _MapStartNavigationButton({
    required this.placeName,
    required this.onTap,
  });

  final String placeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.navigation_rounded),
          label: Text(
            'ابدأ الملاحة الحية إلى $placeName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF173F38),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.count,
    required this.layer,
    required this.onLayerChanged,
    required this.onRefresh,
  });

  final int count;
  final _MapLayer layer;
  final ValueChanged<_MapLayer> onLayerChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, 5)),
          ],
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
                    Text(OuednaStrings.of(context).text('ouedna_map'),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      OuednaStrings.of(context).text(
                        'published_places',
                        values: {'count': '$count'},
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const LanguageSelector(compact: true),
              const SizedBox(width: 2),
              PopupMenuButton<_MapLayer>(
                tooltip: OuednaStrings.of(context).text('map_layer'),
                initialValue: layer,
                onSelected: onLayerChanged,
                itemBuilder: (menuContext) => [
                  PopupMenuItem(
                    value: _MapLayer.standard,
                    child: Text(OuednaStrings.of(context).text('standard_map')),
                  ),
                  PopupMenuItem(
                    value: _MapLayer.satellite,
                    child:
                        Text(OuednaStrings.of(context).text('satellite_map')),
                  ),
                ],
                icon: Icon(
                  layer == _MapLayer.standard
                      ? Icons.layers_outlined
                      : Icons.satellite_alt_outlined,
                ),
              ),
              IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
  const _PlaceImageMarker({
    required this.place,
    required this.selected,
    required this.width,
    required this.height,
  });

  final Place place;
  final bool selected;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const pinGreen = Color(0xFF0E5547);
    final borderColor = selected ? const Color(0xFF0A3E34) : pinGreen;
    final photoSize = width - 16;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.0 : .93,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _PhotoPinPainter(color: borderColor),
            ),
            Positioned(
              top: 7,
              width: photoSize,
              height: photoSize,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: _PlaceImage(
                      imageUrl: place.imageUrl,
                      iconSize: selected ? 27 : 24,
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 1,
                child: Container(
                  width: width - 2,
                  height: width - 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPinPainter extends CustomPainter {
  const _PhotoPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final path = ui.Path()
      ..moveTo(width * .5, 0)
      ..cubicTo(width * .80, 0, width, width * .22, width, width * .49)
      ..cubicTo(
          width, width * .70, width * .72, height * .83, width * .5, height)
      ..cubicTo(width * .28, height * .83, 0, width * .70, 0, width * .49)
      ..cubicTo(0, width * .22, width * .20, 0, width * .5, 0)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(.42), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PhotoPinPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PlacePopupCard extends StatelessWidget {
  const _PlacePopupCard({
    required this.place,
    required this.onDismiss,
    required this.onDetails,
    required this.onNavigate,
  });

  final Place place;
  final VoidCallback onDismiss;
  final VoidCallback onDetails;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 12,
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        shadowColor: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: _PlaceImage(imageUrl: place.imageUrl, iconSize: 30),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AutoTranslatedText(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onDismiss,
                            icon: const Icon(Icons.close_rounded, size: 19),
                            tooltip: OuednaStrings.of(context).text('close'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      AutoTranslatedText(
                        '${place.category} · ${place.locationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          TextButton(
                            onPressed: onDetails,
                            child:
                                Text(OuednaStrings.of(context).text('details')),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onNavigate,
                              icon: const Icon(Icons.directions_rounded,
                                  size: 17),
                              label: const Text('ابدأ الملاحة الحية'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _PlaceCarousel extends StatelessWidget {
  const _PlaceCarousel({
    required this.controller,
    required this.places,
    required this.selectedId,
    required this.onPageChanged,
    required this.onSelect,
  });

  final PageController controller;
  final List<Place> places;
  final int? selectedId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Place> onSelect;

  @override
  Widget build(BuildContext context) => PageView.builder(
        controller: controller,
        itemCount: places.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final place = places[index];
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsetsDirectional.only(
              end: 8,
              top: place.id == selectedId ? 0 : 6,
              bottom: place.id == selectedId ? 0 : 6,
            ),
            child: _PlacePreviewCard(
              place: place,
              selected: place.id == selectedId,
              onTap: () => onSelect(place),
            ),
          );
        },
      );
}

class _PlacePreviewCard extends StatelessWidget {
  const _PlacePreviewCard({
    required this.place,
    required this.selected,
    required this.onTap,
  });

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
                  width: 92,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _PlaceImage(imageUrl: place.imageUrl, iconSize: 30),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AutoTranslatedText(
                          place.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 15, color: Colors.black54),
                            const SizedBox(width: 3),
                            Expanded(
                              child: AutoTranslatedText(
                                place.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
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
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.blue.withOpacity(.25), shape: BoxShape.circle),
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
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(
            OuednaStrings.of(context).text('no_coordinates'),
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
          label: Text(OuednaStrings.of(context).text('map_load_error')),
        ),
      );
}
