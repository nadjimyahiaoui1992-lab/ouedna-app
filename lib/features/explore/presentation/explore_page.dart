import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    required this.placeRepository,
    required this.isBackendConfigured,
  });

  final PlaceRepository? placeRepository;
  final bool isBackendConfigured;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchController = TextEditingController();
  List<Place> _places = const [];
  Object? _error;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces({String? query}) async {
    final repository = widget.placeRepository;
    if (repository == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final places = await repository.getPublishedPlaces(query: query);
      if (!mounted) return;
      setState(() => _places = places);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _loadPlaces(query: _searchController.text),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'El Oued, autrement',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Préparez une visite attentive des lieux, des savoir-faire et des paysages du Souf.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _loadPlaces(query: value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un lieu ou une ambiance',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Effacer la recherche',
                          onPressed: () {
                            _searchController.clear();
                            _loadPlaces();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _DiscoveryBanner(),
                    const SizedBox(height: 24),
                    Text(
                      'Lieux à découvrir',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (!widget.isBackendConfigured)
                      const _ConfigurationNotice(),
                    if (_error != null) _ErrorNotice(onRetry: _loadPlaces),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_places.isEmpty &&
                widget.isBackendConfigured &&
                _error == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyPlaces(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList.separated(
                  itemCount: _places.length,
                  itemBuilder: (context, index) =>
                      _PlaceCard(place: _places[index]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryBanner extends StatelessWidget {
  const _DiscoveryBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Conseil de préparation de visite',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voyager avec justesse',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Vérifiez les horaires et privilégiez les heures fraîches. Le guide IA peut vous aider à organiser votre parcours.',
                    style: TextStyle(color: Colors.white, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigurationNotice extends StatelessWidget {
  const _ConfigurationNotice();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mode démonstration : injectez SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY pour afficher les lieux publiés.',
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.onRetry});

  final Future<void> Function({String? query}) onRetry;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Les contenus sont indisponibles actuellement.')),
              TextButton(
                  onPressed: () => onRetry(), child: const Text('Réessayer')),
            ],
          ),
        ),
      );
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucun lieu ne correspond à cette recherche.'),
        ),
      );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPlaceSheet(context, place),
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              SizedBox(
                  width: 124,
                  height: double.infinity,
                  child: _PlaceImage(place: place)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.category,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 4),
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
                      Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (place.rating != null)
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: scheme.secondary, size: 18),
                            const SizedBox(width: 4),
                            Text(place.rating!.toStringAsFixed(1)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceSheet(BuildContext context, Place selectedPlace) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selectedPlace.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(selectedPlace.description,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (selectedPlace.openingHours != null) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text(selectedPlace.openingHours!)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Demander au guide IA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.imageUrl;
    if (imageUrl == null || !imageUrl.startsWith('https://')) {
      return _fallback(context);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 360,
      placeholder: (_, __) => _fallback(context),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 38,
          ),
        ),
      );
}
