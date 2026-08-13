import 'package:flutter/material.dart';
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
    final places = await widget.repository?.getPublishedPlaces() ?? const <Place>[];
    return places
        .where((place) => widget.favorites.isFavorite(place.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: FutureBuilder<List<Place>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل المفضلة حالياً.'));
          }
          final places = snapshot.data ?? const <Place>[];
          if (places.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 64),
                    SizedBox(height: 12),
                    Text('لم تحفظ أي معلم بعد.',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                      'اضغط على رمز القلب في تفاصيل أي معلم لإضافته هنا.',
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
                  leading: const CircleAvatar(
                      child: Icon(Icons.place_outlined)),
                  title: Text(place.name,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${place.category} · ${place.locationLabel}'),
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
