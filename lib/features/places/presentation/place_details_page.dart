import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../routing/domain/routing_service.dart';
import '../../routing/presentation/navigation_page.dart';
import '../domain/entities/place.dart';
import '../domain/entities/place_gallery_image.dart';
import '../domain/repositories/place_repository.dart';

class PlaceDetailsPage extends StatefulWidget {
  const PlaceDetailsPage({
    super.key,
    required this.place,
    required this.repository,
    required this.favorites,
    this.routingService,
  });

  final Place place;
  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  late Future<List<PlaceGalleryImage>> _galleryFuture;

  @override
  void initState() {
    super.initState();
    _galleryFuture = widget.repository?.getPlaceGallery(widget.place.id) ??
        Future<List<PlaceGalleryImage>>.value(const []);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: place.hasCoordinates
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NavigationPage(
                        place: place,
                        routingService: widget.routingService,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('ابدأ الملاحة إلى المكان'),
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
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(place: place),
            ),
            actions: [
              AnimatedBuilder(
                animation: widget.favorites,
                builder: (context, _) {
                  final saved = widget.favorites.contains(place.id);
                  return IconButton(
                    tooltip: saved ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                    onPressed: () => widget.favorites.toggle(place.id),
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                    color: saved ? scheme.error : null,
                  );
                },
              ),
              IconButton(
                tooltip: 'مشاركة المكان',
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(place.category)),
                      if (place.subCategory?.isNotEmpty == true)
                        Chip(label: Text(place.subCategory!)),
                      if (place.rating != null)
                        Chip(
                          avatar: const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFD9A441)),
                          label: Text(place.rating!.toStringAsFixed(1)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    place.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: place.locationLabel),
                  if (place.openingHours?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                        icon: Icons.schedule_outlined,
                        text: place.openingHours!),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'نبذة عن المكان',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(place.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.65)),
                  const SizedBox(height: 28),
                  _Actions(
                    place: place,
                    routingService: widget.routingService,
                  ),
                  const SizedBox(height: 30),
                  FutureBuilder<List<PlaceGalleryImage>>(
                    future: _galleryFuture,
                    builder: (context, snapshot) {
                      final gallery = snapshot.data ?? const [];
                      if (gallery.isEmpty) return const SizedBox.shrink();
                      return _Gallery(gallery: gallery);
                    },
                  ),
                  if (place.hasCoordinates) ...[
                    const SizedBox(height: 30),
                    Text('الموقع على الخريطة',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _MiniMap(place: place),
                  ],
                  if (_hasContact(place)) ...[
                    const SizedBox(height: 30),
                    Text('معلومات التواصل',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (place.phone?.isNotEmpty == true)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text(place.phone!),
                        onTap: () =>
                            _launch(Uri(scheme: 'tel', path: place.phone)),
                      ),
                    if (place.website?.isNotEmpty == true)
                      ListTile(
                        leading: const Icon(Icons.language_outlined),
                        title: const Text('الموقع الإلكتروني'),
                        onTap: () => _launch(Uri.tryParse(place.website!)),
                      ),
                    if (place.instagram?.isNotEmpty == true)
                      ListTile(
                        leading: const Icon(Icons.camera_alt_outlined),
                        title: const Text('Instagram'),
                        onTap: () => _launch(Uri.tryParse(place.instagram!)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasContact(Place place) =>
      place.phone?.isNotEmpty == true ||
      place.website?.isNotEmpty == true ||
      place.instagram?.isNotEmpty == true;

  Future<void> _sharePlace(Place place) async {
    final coordinates =
        place.hasCoordinates ? '\n${place.latitude}, ${place.longitude}' : '';
    final deepLink = 'https://souf360.vercel.app/place/${place.id}';
    await Share.share(
        '${place.name}\n${place.description}$coordinates\n$deepLink');
  }

  Future<void> _launch(Uri? uri) async {
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFFD9A441)
          ]),
        ),
        child: const Center(
            child:
                Icon(Icons.landscape_outlined, size: 82, color: Colors.white)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest),
      errorWidget: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.broken_image_outlined, size: 64),
      ),
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
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.place, required this.routingService});

  final Place place;
  final RoutingService? routingService;

  Future<void> _openExternalDirections(BuildContext context) async {
    final destination = '${place.latitude},${place.longitude}';
    final geoUri = Uri(
      scheme: 'geo',
      path: destination,
      queryParameters: {'q': '$destination(${place.name})'},
    );
    try {
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A web fallback still gives visitors directions on devices without a map app.
    }

    final webUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final launched =
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الخرائط على هذا الجهاز.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: !place.hasCoordinates
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NavigationPage(
                          place: place,
                          routingService: routingService,
                        ),
                      ),
                    ),
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('الملاحة داخل التطبيق'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !place.hasCoordinates
                ? null
                : () => _openExternalDirections(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('فتح في تطبيق الخرائط'),
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
          Text('الصور',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final image = gallery[index];
                return Semantics(
                  label: image.title ?? 'صورة للمكان',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      width: 176,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(
                          width: 176, child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                );
              },
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
          options: MapOptions(
              initialCenter: point,
              initialZoom: 14,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all)),
          children: [
            TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.souf360.app'),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 46,
                  height: 46,
                  child: const Icon(Icons.location_on,
                      color: Color(0xFFD9A441), size: 44),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
