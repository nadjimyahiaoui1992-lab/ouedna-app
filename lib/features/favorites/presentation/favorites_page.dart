import 'package:flutter/material.dart';

import '../../../core/localization/ouedna_localization.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    widget.favorites.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    widget.favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() => _future = _load());
  }

  Future<List<Place>> _load() async {
    final places =
        await widget.repository?.getPublishedPlaces() ?? const <Place>[];
    return places
        .where((place) => widget.favorites.isFavorite(place.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = OuednaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('favorites'))),
      body: FutureBuilder<List<Place>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(strings.text('favorites_load_error')));
          }
          final places = snapshot.data ?? const <Place>[];
          if (places.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      strings.text('no_saved_places'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.text('no_saved_places_info'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final place = places[index];
              return Card(
                child: ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailsPage(
                        place: place,
                        repository: widget.repository,
                        favorites: widget.favorites,
                        routingService: widget.routingService,
                      ),
                    ),
                  ),
                  leading:
                      const CircleAvatar(child: Icon(Icons.place_outlined)),
                  title: AutoTranslatedText(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: AutoTranslatedText(
                    '${place.category} · ${place.locationLabel}',
                  ),
                  trailing: IconButton(
                    onPressed: () => widget.favorites.toggle(place.id),
                    icon: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
