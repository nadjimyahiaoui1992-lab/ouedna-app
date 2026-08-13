import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../routing/domain/routing_service.dart';
import 'place_details_page.dart';
import '../domain/entities/place.dart';
import '../domain/repositories/place_repository.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, required this.repository, required this.favorites, required this.routingService});
  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;
  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final _searchController = TextEditingController();
  String? _category;
  late Future<List<Place>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  Future<List<Place>> _load() => widget.repository?.getPublishedPlaces(query: _searchController.text) ?? Future.value(const []);
  void _reload() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المعالم'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(labelText: 'ابحث عن معلم أو مكان', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: IconButton(onPressed: _reload, icon: const Icon(Icons.arrow_forward_rounded)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Place>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return _ErrorState(onRetry: _reload);
                final places = (snapshot.data ?? const <Place>[]).where((place) => _category == null || place.category == _category).toList();
                if (places.isEmpty) return const Center(child: Text('لا توجد معالم منشورة مطابقة للبحث.'));
                final categories = places.map((e) => e.category).toSet().toList()..sort();
                return Column(
                  children: [
                    if (categories.isNotEmpty) SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [ChoiceChip(label: const Text('الكل'), selected: _category == null, onSelected: (_) => setState(() => _category = null)), ...categories.map((category) => Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category))))])),
                    Expanded(child: RefreshIndicator(onRefresh: () async => _reload(), child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 10, 16, 28), itemCount: places.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _PlaceTile(place: places[index], favorites: widget.favorites, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: places[index], repository: widget.repository, favorites: widget.favorites, routingService: widget.routingService))))))),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.favorites, required this.onTap});
  final Place place;
  final FavoritesController favorites;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(children: [
            SizedBox(width: 118, height: 118, child: place.imageUrl?.isNotEmpty == true ? CachedNetworkImage(imageUrl: place.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFFE4ECE8), child: Icon(Icons.landscape_outlined))) : const ColoredBox(color: Color(0xFFE4ECE8), child: Icon(Icons.landscape_outlined))),
            Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), AnimatedBuilder(animation: favorites, builder: (_, __) => Icon(favorites.isFavorite(place.id) ? Icons.favorite : Icons.favorite_border, color: favorites.isFavorite(place.id) ? Colors.red : Colors.grey, size: 20))]), const SizedBox(height: 8), Text(place.category, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(place.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)]))),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 48), const SizedBox(height: 12), const Text('تعذر تحميل المعالم حالياً.'), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))]));
}
