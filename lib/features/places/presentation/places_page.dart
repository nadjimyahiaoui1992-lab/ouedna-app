import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../../core/widgets/offline_catalogue_notice.dart';
import '../domain/entities/place.dart';
import '../domain/entities/place_page.dart';
import '../domain/repositories/place_repository.dart';
import '../../routing/domain/routing_service.dart';
import 'add_place_visitor_dialog.dart';
import 'place_details_page.dart';
import 'widgets/place_card.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.repository,
    required this.favorites,
    this.routingService,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  static const _pageSize = 12;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  StreamSubscription<void>? _subscription;
  List<Place> _places = const [];
  List<String> _categories = const [];
  String? _selectedCategory;
  String? _error;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _scrollController.addListener(_onScroll);
    _subscription =
        widget.repository?.watchPublishedPlaces().listen((_) => _refresh());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _subscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320) _loadMore();
  }

  Future<void> _refresh() async {
    final repository = widget.repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _error = 'لا يتوفر اتصال بمصدر بيانات Souf360.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      final results = await Future.wait([
        repository.getPublishedPlacesPage(
          query: _searchController.text,
          category: _selectedCategory,
          limit: _pageSize,
        ),
        repository.getPublishedCategories(),
      ]);
      if (!mounted) return;
      final page = results[0] as PlacePage;
      setState(() {
        _places = page.places;
        _categories = results[1] as List<String>;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المعالم. تحقق من اتصال الإنترنت ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || widget.repository == null)
      return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository!.getPublishedPlacesPage(
        query: _searchController.text,
        category: _selectedCategory,
        offset: _places.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _places = [..._places, ...page.places];
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  void _openDetails(Place place) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: widget.repository,
            favorites: widget.favorites,
            routingService: widget.routingService,
          ),
        ),
      );

  void _openAddPlace() {
    showDialog(
      context: context,
      builder: (_) => AddPlaceVisitorDialog(repository: widget.repository),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddPlace,
          backgroundColor: const Color(0xFF193F38),
          icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFFD9A441)),
          label: const Text('اقترح معلماً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المعالم والأماكن',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('استكشف الأماكن المنشورة من Souf360',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو الوصف أو المنطقة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _searchController.clear();
                                _refresh();
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_categories.isNotEmpty)
              SizedBox(
                height: 46,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('الكل'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                        _refresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map(
                      (category) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                            _refresh();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.repository is OfflineAwarePlaceRepository &&
                (widget.repository as OfflineAwarePlaceRepository)
                    .isUsingCachedData)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
                child: OfflineCatalogueNotice(),
              ),
            const SizedBox(height: 6),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );

  Widget _buildResults() {
    if (_loading) return const _PlacesSkeleton();
    if (_error != null)
      return _PlacesError(message: _error!, onRetry: _refresh);
    if (_places.isEmpty) return const _EmptyPlaces();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        itemCount: _places.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _places.length)
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          final place = _places[index];
          return PlaceCard(
            place: place,
            favorites: widget.favorites,
            onTap: () => _openDetails(place),
          );
        },
      ),
    );
  }
}

class _PlacesSkeleton extends StatelessWidget {
  const _PlacesSkeleton();
  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 142,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
}

class _PlacesError extends StatelessWidget {
  const _PlacesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
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
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore_outlined, size: 52),
              SizedBox(height: 12),
              Text('لا توجد أماكن مطابقة لبحثك.'),
            ],
          ),
        ),
      );
}
