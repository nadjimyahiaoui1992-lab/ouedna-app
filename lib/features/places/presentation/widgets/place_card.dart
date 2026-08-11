import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/storage/favorites_controller.dart';
import '../../domain/entities/place.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.favorites,
    required this.onTap,
    this.compact = false,
  });

  final Place place;
  final FavoritesController favorites;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'فتح تفاصيل ${place.name}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: compact
              ? _compactCard(context, scheme)
              : _listCard(context, scheme),
        ),
      ),
    );
  }

  Widget _compactCard(BuildContext context, ColorScheme scheme) => SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(context, height: 126),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _listCard(BuildContext context, ColorScheme scheme) => SizedBox(
        height: 142,
        child: Row(
          children: [
            SizedBox(
                width: 136,
                height: double.infinity,
                child: _image(context, height: 142)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: scheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        _favoriteButton(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        place.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.35),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
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
      );

  Widget _image(BuildContext context, {required double height}) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = place.imageUrl;
    if (imageUrl == null) {
      return ColoredBox(
        color: scheme.secondaryContainer,
        child: const Center(child: Icon(Icons.landscape_outlined, size: 38)),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).round(),
      placeholder: (_, __) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_outlined)),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: scheme.secondaryContainer,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }

  Widget _favoriteButton() => AnimatedBuilder(
        animation: favorites,
        builder: (context, _) {
          final isFavorite = favorites.contains(place.id);
          return IconButton(
            tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            onPressed: () => favorites.toggle(place.id),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Theme.of(context).colorScheme.error : null,
          );
        },
      );
}
