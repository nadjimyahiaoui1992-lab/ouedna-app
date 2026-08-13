import 'package:cached_network_image/cached_network_image.dart';
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
      bottomNavigationBar: place.hasCoordinates
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: FilledButton.icon(
                  onPressed: widget.routingService == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LiveNavigationPage(
                                place: place,
                                routingService: widget.routingService!,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text(strings.text('navigate_to_place')),
                ),
              ),
            )
          : null,
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
                  AutoTranslatedText(
                    place.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.65),
                  ),
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

class _Actions extends StatelessWidget {
  const _Actions({required this.place, required this.routingService});

  final Place place;
  final RoutingService? routingService;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
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
            icon: const Icon(Icons.navigation_outlined),
            label: Text(OuednaStrings.of(context).text('in_app_navigation')),
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

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(place.latitude!, place.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ouedna.app',
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
    );
  }
}
