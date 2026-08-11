import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../places/presentation/widgets/place_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.repository,
    required this.favorites,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<List<Place>>? _future;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _reload();
    _subscription =
        widget.repository?.watchPublishedPlaces().listen((_) => _reload());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _loadPlaces();
    });
  }

  Future<List<Place>> _loadPlaces() async {
    final repository = widget.repository;
    if (repository == null) return const [];
    return repository.getPublishedPlaces();
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
  Widget build(BuildContext context) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.favorites,
          builder: (context, _) => FutureBuilder<List<Place>>(
            future: _future,
            builder: (context, snapshot) {
              final places = (snapshot.data ?? const <Place>[])
                  .where((place) => widget.favorites.contains(place.id))
                  .toList(growable: false);
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Text('المفضلة',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('الأماكن التي حفظتها لرحلتك',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator()))
                    else if (places.isEmpty)
                      const _EmptyFavorites()
                    else
                      ...places.map(
                        (place) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PlaceCard(
                            place: place,
                            favorites: widget.favorites,
                            onTap: () => _openDetails(place),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 72),
        child: Column(
          children: [
            Icon(Icons.favorite_border,
                size: 58, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text('لم تحفظ أي مكان بعد',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('استخدم رمز القلب في بطاقات المعالم لتجهيز قائمة رحلتك.',
                textAlign: TextAlign.center),
          ],
        ),
      );
}
