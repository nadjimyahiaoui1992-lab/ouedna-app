import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/ouedna_localization.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../community/domain/repositories/community_repository.dart';
import '../../routing/domain/routing_service.dart';
import '../../routing/presentation/live_navigation_page.dart';
import '../domain/entities/place.dart';
import '../domain/entities/place_gallery_image.dart';
import '../domain/repositories/place_repository.dart';
import 'place_feedback_dialog.dart';

class PlaceDetailsPage extends StatefulWidget {
  const PlaceDetailsPage({
    super.key,
    required this.place,
    required this.repository,
    required this.favorites,
    this.routingService,
    this.communityRepository,
  });

  final Place place;
  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;
  final CommunityRepository? communityRepository;

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  late Future<List<PlaceGalleryImage>> _galleryFuture;

  @override
  void initState() {
    super.initState();
    _galleryFuture = widget.repository?.getPlaceGallery(widget.place.id) ??
        Future.value(const []);
  }

  void _openFeedback() {
    if (widget.communityRepository == null) return;
    showDialog(
      context: context,
      builder: (_) => PlaceFeedbackDialog(
        placeId: widget.place.id,
        communityRepository: widget.communityRepository!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final scheme = Theme.of(context).colorScheme;
    final strings = OuednaStrings.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 286,
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            flexibleSpace:
                FlexibleSpaceBar(background: _HeroImage(place: place)),
            actions: [
              AnimatedBuilder(
                animation: widget.favorites,
                builder: (context, _) {
                  final saved = widget.favorites.contains(place.id);
                  return IconButton(
                    onPressed: () => widget.favorites.toggle(place.id),
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                    color: saved ? scheme.error : null,
                  );
                },
              ),
              IconButton(
                onPressed: () => _sharePlace(place),
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: AutoTranslatedText(place.category)),
                      const SizedBox(width: 8),
                      if (place.subCategory?.isNotEmpty == true)
                        Flexible(
                          child: Chip(
                            label: AutoTranslatedText(place.subCategory!),
                          ),
                        ),
                      const Spacer(),
                      if (widget.communityRepository != null)
                        TextButton.icon(
                          onPressed: _openFeedback,
                          icon:
                              const Icon(Icons.rate_review_outlined, size: 18),
                          label: Text(strings.text('add_review')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AutoTranslatedText(
                    place.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: place.locationLabel),
                  if (place.openingHours?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      text: place.openingHours!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    strings.text('about_place'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _ReadableDescription(description: place.description),
                  const SizedBox(height: 28),
                  _Actions(place: place, routingService: widget.routingService),
                  const SizedBox(height: 30),
                  FutureBuilder<List<PlaceGalleryImage>>(
                    future: _galleryFuture,
                    builder: (context, snapshot) {
                      final gallery =
                          snapshot.data ?? const <PlaceGalleryImage>[];
                      if (gallery.isEmpty) return const SizedBox.shrink();
                      return _Gallery(gallery: gallery);
                    },
                  ),
                  if (place.hasCoordinates) ...[
                    const SizedBox(height: 30),
                    Text(
                      strings.text('location_on_map'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _MiniMap(place: place),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePlace(Place place) async {
    final deepLink = 'https://ouedna.vercel.app/place/${place.id}';
    final strings = OuednaStrings.of(context);
    await Share.share(
      '${place.name}\n${place.description}\n\n${strings.text('discover_more')}\n$deepLink',
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final url = place.imageUrl;
    if (url == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFFD9A441)
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.landscape_outlined, size: 82, color: Colors.white),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest),
      errorWidget: (_, __, ___) => const ColoredBox(
          color: Colors.grey,
          child: Icon(Icons.broken_image_outlined, size: 64)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: AutoTranslatedText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
}

class _ReadableDescription extends StatelessWidget {
  const _ReadableDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final paragraphs = description
        .split(RegExp(r'\n\s*\n|\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.isEmpty) {
      return const Text('لا توجد نبذة متاحة حالياً.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          AutoTranslatedText(
            paragraphs[index],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.75,
                  fontSize: 16,
                ),
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.place, required this.routingService});

  final Place place;
  final RoutingService? routingService;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: !place.hasCoordinates || routingService == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LiveNavigationPage(
                          place: place,
                          routingService: routingService!,
                        ),
                      ),
                    ),
            icon: const Icon(Icons.route_rounded, size: 20),
            label: const Text('ابدأ المسار'),
          ),
        ],
      );
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.gallery});

  final List<PlaceGalleryImage> gallery;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OuednaStrings.of(context).text('photos'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  imageUrl: gallery[index].imageUrl,
                  width: 176,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
        ],
      );
}

class _MiniMap extends StatefulWidget {
  const _MiniMap({required this.place});

  final Place place;

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  late final StreamController<void> _resetController;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resetController = StreamController<void>.broadcast();
  }

  @override
  void dispose() {
    _resetController.close();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _resetController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.place.latitude!, widget.place.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ouedna.app.v2',
                    reset: _resetController.stream,
                    tileBuilder: (context, tileWidget, tile) => AnimatedBuilder(
                      animation: tile,
                      builder: (context, child) {
                        if (tile.readyToDisplay) {
                          if (_loading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _loading = false);
                            });
                          }
                          return child!;
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Color(0xFFECE7DE)),
                            Center(
                              child: tile.loadError
                                  ? const Icon(Icons.cloud_off_outlined)
                                  : const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                      child: tileWidget,
                    ),
                    errorTileCallback: (_, __, ___) {
                      if (mounted) setState(() => _hasError = true);
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_hasError)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withOpacity(.82),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل الخريطة'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_loading)
              const PositionedDirectional(
                start: 12,
                bottom: 12,
                child: _MapLoadingPill(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapLoadingPill extends StatelessWidget {
  const _MapLoadingPill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('جارٍ تحميل الموقع...'),
            ],
          ),
        ),
      );
}
