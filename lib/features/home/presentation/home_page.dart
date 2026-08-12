import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
              final photoPlaces = featured
                  .where((place) => place.imageUrl?.trim().isNotEmpty == true)
                  .toList(growable: false);
              final displayFeatured =
                  photoPlaces.isEmpty ? featured : photoPlaces;
              final heroPlace = photoPlaces.isEmpty ? null : photoPlaces.first;
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
                    heroPlace: heroPlace,
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
                    height: 94,
                    child: _CategoryRail(
                      categories: data.categories,
                      onExplore: widget.onExplore,
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
                      itemCount: displayFeatured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _FeaturedPlaceCard(
                        place: displayFeatured[index],
                        onTap: () => _openPlace(displayFeatured[index]),
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
  const _WelcomePanel({
    required this.heroPlace,
    required this.onExplore,
    required this.onMap,
  });

  final Place? heroPlace;
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
              if (heroPlace?.imageUrl?.trim().isNotEmpty == true)
                CachedNetworkImage(
                  imageUrl: heroPlace!.imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, __) => const ColoredBox(
                    color: Color(0xFF193F38),
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF193F38),
                  ),
                )
              else
                const ColoredBox(color: Color(0xFF193F38)),
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
                    Text(
                      heroPlace?.name ?? 'رحلتك تبدأ من هنا',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      heroPlace == null
                          ? 'معالم الوادي وتجارب الزوار المنشورة'
                          : '${heroPlace!.category} · ${heroPlace!.locationLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4EBDD),
                        fontWeight: FontWeight.w600,
                      ),
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

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.categories, required this.onExplore});

  final List<String> categories;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CategoryCircle(
          label: categories[index],
          onTap: onExplore,
        ),
      );
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  IconData get _icon {
    if (label.contains('فندق') || label.contains('منتجع')) {
      return Icons.hotel_outlined;
    }
    if (label.contains('مطعم') || label.contains('مقهى')) {
      return Icons.restaurant_outlined;
    }
    if (label.contains('سوق') || label.contains('أسواق')) {
      return Icons.storefront_outlined;
    }
    if (label.contains('متجر') || label.contains('محلات')) {
      return Icons.shopping_bag_outlined;
    }
    if (label.contains('طبيعي') || label.contains('واحة')) {
      return Icons.park_outlined;
    }
    if (label.contains('صحي')) return Icons.local_hospital_outlined;
    if (label.contains('تراث') || label.contains('أثر')) {
      return Icons.account_balance_outlined;
    }
    return Icons.explore_outlined;
  }

  Color get _color {
    if (label.contains('فندق') || label.contains('منتجع')) {
      return const Color(0xFF1E8A8A);
    }
    if (label.contains('مطعم') || label.contains('مقهى')) {
      return const Color(0xFFC47C36);
    }
    if (label.contains('سوق') || label.contains('أسواق')) {
      return const Color(0xFFC08A2E);
    }
    if (label.contains('متجر') || label.contains('محلات')) {
      return const Color(0xFF2E8B9E);
    }
    if (label.contains('طبيعي') || label.contains('واحة')) {
      return const Color(0xFF478B56);
    }
    if (label.contains('صحي')) return const Color(0xFF3E87B6);
    return const Color(0xFFD9A441);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'استكشف فئة $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color.withOpacity(.28)),
                    ),
                    child: Icon(_icon, color: _color, size: 26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'فتح ${place.name}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: 246,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.imageUrl?.trim().isNotEmpty == true)
                    CachedNetworkImage(
                      imageUrl: place.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFF193F38),
                      ),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF193F38),
                      ),
                    )
                  else
                    const ColoredBox(color: Color(0xFF193F38)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE6102D28)],
                        stops: [.32, 1],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9102D28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          color: Color(0xFFF5EBDD),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 14,
                    end: 14,
                    bottom: 13,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFE5B65A), size: 17),
                            const SizedBox(width: 3),
                            Text(
                              (place.rating ?? 0).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                place.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF5EBDD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  label: 'مساعد ذكي',
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
