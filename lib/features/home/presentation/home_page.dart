import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/favorites_controller.dart';
import '../../../core/widgets/emergency_assistance_sheet.dart';
import '../../../core/widgets/offline_catalogue_notice.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../places/presentation/widgets/place_card.dart';
import '../../compass/presentation/compass_page.dart';
import '../../routing/domain/routing_service.dart';
import '../../tour_guide/domain/repositories/tour_guide_repository.dart';
import '../../tour_guide/presentation/tour_guide_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.tourGuideRepository,
    this.routingService,
    required this.onExplore,
    required this.onMap,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final TourGuideRepository? tourGuideRepository;
  final RoutingService? routingService;
  final VoidCallback onExplore;
  final VoidCallback onMap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<_HomeData>? _future;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscription =
        widget.repository?.watchPublishedPlaces().listen((_) => _refresh());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<_HomeData> _load() async {
    final repository = widget.repository;
    if (repository == null) throw StateError('لا يتوفر اتصال بمصدر البيانات.');
    final response = await Future.wait([
      repository.getPublishedPlacesPage(limit: 20),
      repository.getPublishedCategories(),
    ]);
    return _HomeData(
      places: (response[0] as dynamic).places as List<Place>,
      categories: response[1] as List<String>,
    );
  }

  void _openGuide() => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) =>
                TourGuidePage(repository: widget.tourGuideRepository)),
      );

  void _openCompass() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompassPage(
            repository: widget.repository,
            favorites: widget.favorites,
            routingService: widget.routingService,
            onMap: widget.onMap,
          ),
        ),
      );

  void _openEmergency() => showEmergencyAssistanceSheet(context);

  void _openPlace(Place place) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: widget.repository,
            favorites: widget.favorites,
            routingService: widget.routingService,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: FutureBuilder<_HomeData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const _HomeSkeleton();
              if (snapshot.hasError) return _HomeError(onRetry: _refresh);
              final data = snapshot.data!;
              final isOffline =
                  widget.repository is OfflineAwarePlaceRepository &&
                      (widget.repository as OfflineAwarePlaceRepository)
                          .isUsingCachedData;
              final featured = [...data.places]
                ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Text(
                    'سوف 360',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'اكتشف وادي سوف من كل زاوية',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _HomeActionRail(
                    onGuide: _openGuide,
                    onCompass: _openCompass,
                    onMap: widget.onMap,
                    onEmergency: _openEmergency,
                  ),
                  const SizedBox(height: 18),
                  _WelcomePanel(
                    onExplore: widget.onExplore,
                    onMap: widget.onMap,
                  ),
                  if (isOffline) ...[
                    const SizedBox(height: 12),
                    const OfflineCatalogueNotice(),
                  ],
                  const SizedBox(height: 20),
                  Semantics(
                    textField: true,
                    label: 'ابحث عن معلم أو مكان',
                    child: TextField(
                      readOnly: true,
                      onTap: widget.onExplore,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن معلم أو مكان...',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: Icon(Icons.tune_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(
                      title: 'استكشف حسب الفئة',
                      action: 'كل المعالم',
                      onAction: widget.onExplore),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ActionChip(
                        avatar: const Icon(Icons.category_outlined, size: 17),
                        label: Text(data.categories[index]),
                        onPressed: widget.onExplore,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                      title: 'أماكن مميزة',
                      action: 'عرض الكل',
                      onAction: widget.onExplore),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => PlaceCard(
                        place: featured[index],
                        favorites: widget.favorites,
                        compact: true,
                        onTap: () => _openPlace(featured[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                      title: 'أحدث الإضافات',
                      action: 'عرض الكل',
                      onAction: widget.onExplore),
                  const SizedBox(height: 12),
                  ...data.places.take(5).map(
                        (place) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PlaceCard(
                            place: place,
                            favorites: widget.favorites,
                            onTap: () => _openPlace(place),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
}

class _HomeData {
  const _HomeData({required this.places, required this.categories});
  final List<Place> places;
  final List<String> categories;
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.onExplore, required this.onMap});

  final VoidCallback onExplore;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 174,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/branding/souf360_el_oued_welcome.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, .35),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xDC102D28), Color(0x65102D28)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رحلتك تبدأ من هنا',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'معالم الوادي وتجارب الزوار المنشورة',
                      style: TextStyle(
                          color: Color(0xFFF4EBDD),
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE5B65A),
                            foregroundColor: const Color(0xFF102D28),
                          ),
                          onPressed: onExplore,
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('استكشف'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white),
                          onPressed: onMap,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('الخريطة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeActionRail extends StatelessWidget {
  const _HomeActionRail({
    required this.onGuide,
    required this.onCompass,
    required this.onMap,
    required this.onEmergency,
  });

  final VoidCallback onGuide;
  final VoidCallback onCompass;
  final VoidCallback onMap;
  final VoidCallback onEmergency;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: _HomeAction(
                  icon: Icons.auto_awesome_outlined,
                  label: 'الدليل',
                  onTap: onGuide)),
          const SizedBox(width: 8),
          Expanded(
              child: _HomeAction(
                  icon: Icons.explore_outlined,
                  label: 'بوصلة',
                  onTap: onCompass)),
          const SizedBox(width: 8),
          Expanded(
              child: _HomeAction(
                  icon: Icons.map_outlined, label: 'الخريطة', onTap: onMap)),
          const SizedBox(width: 8),
          Expanded(
              child: _HomeAction(
                  icon: Icons.sos_outlined,
                  label: 'نجدة',
                  isEmergency: true,
                  onTap: onEmergency)),
        ],
      );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final color = isEmergency
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 5),
                FittedBox(
                  child: Text(label,
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.action, required this.onAction});
  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900))),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
              height: 26,
              width: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHighest),
          const SizedBox(height: 20),
          Container(
              height: 118,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 18),
          Container(
              height: 58,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18))),
        ],
      );
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});
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
              const Text('لا يوجد اتصال بالإنترنت أو لا تتوفر بيانات محفوظة.'),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}
