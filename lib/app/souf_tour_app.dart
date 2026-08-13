import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/storage/favorites_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/community/presentation/community_page.dart';
import '../features/favorites/presentation/favorites_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/map/presentation/souf_map_page.dart';
import '../features/places/domain/repositories/place_repository.dart';
import '../features/places/presentation/place_details_page.dart';
import '../features/places/presentation/places_page.dart';
import '../features/routing/domain/routing_service.dart';
import '../features/tour_guide/domain/repositories/tour_guide_repository.dart';
import '../features/welcome/presentation/welcome_page.dart';
import '../features/welcome/presentation/privacy_policy_page.dart';
import '../features/updates/presentation/update_center_page.dart';
import '../features/updates/data/app_update_service.dart';

class OuednaApp extends StatefulWidget {
  const OuednaApp({
    super.key,
    required this.placeRepository,
    required this.communityRepository,
    required this.tourGuideRepository,
    this.routingService,
    required this.favoritesController,
    required this.isBackendConfigured,
  });

  final PlaceRepository? placeRepository;
  final CommunityRepository? communityRepository;
  final TourGuideRepository? tourGuideRepository;
  final RoutingService? routingService;
  final FavoritesController favoritesController;
  final bool isBackendConfigured;

  @override
  State<OuednaApp> createState() => _OuednaAppState();
}

class _OuednaAppState extends State<OuednaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  var _selectedIndex = 0;
  var _themeMode = ThemeMode.system;
  var _showWelcome = true;
  int? _openingPlaceId;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleDeepLink(initialLink);
      _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) {
    final placeId = _placeIdFromUri(uri);
    if (placeId == null || _openingPlaceId == placeId) return;
    setState(() {
      _showWelcome = false;
      _selectedIndex = 1;
      _openingPlaceId = placeId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSharedPlace(placeId));
  }

  int? _placeIdFromUri(Uri uri) {
    if (uri.scheme == 'ouedna' && uri.host == 'place') {
      return uri.pathSegments.isEmpty ? null : int.tryParse(uri.pathSegments.first);
    }
    if (uri.scheme == 'https' && uri.host == 'ouedna.vercel.app' && uri.pathSegments.length >= 2 && uri.pathSegments.first == 'place') {
      return int.tryParse(uri.pathSegments[1]);
    }
    return null;
  }

  Future<void> _openSharedPlace(int placeId) async {
    final repository = widget.placeRepository;
    final navigator = _navigatorKey.currentState;
    if (repository == null || navigator == null) return;

    try {
      final place = await repository.getPublishedPlaceById(placeId);
      if (!mounted || place == null) return;
      await navigator.push(MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place, repository: repository, favorites: widget.favoritesController, routingService: widget.routingService)));
    } catch (_) {} finally {
      if (mounted && _openingPlaceId == placeId) setState(() => _openingPlaceId = null);
    }
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _enterApp() {
    setState(() => _showWelcome = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptForUpdate());
  }

  Future<void> _maybePromptForUpdate() async {
    final service = AppUpdateService();
    try {
      final update = await service.checkForUpdate();
      if (!mounted || update == null || !update.isUpdateAvailable) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !update.forceUpdate,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.system_update_alt_rounded, size: 38),
          title: Text('يتوفر تحديث ${update.latestVersion}'),
          content: Text(update.releaseNotes?.isNotEmpty == true ? update.releaseNotes! : 'يتوفر إصدار أحدث من وادنا لتحسين الأداء والأمان.'),
          actions: [
            if (!update.forceUpdate)
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لاحقاً')),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const UpdateCenterPage()));
              },
              child: const Text('عرض التحديث'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Updates are optional; network errors must not block access to tourism content.
    } finally {
      service.dispose();
    }
  }

  void _toggleTheme() => setState(() => _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(repository: widget.placeRepository, favorites: widget.favoritesController, routingService: widget.routingService, onExplore: () => _select(1), onMap: () => _select(2)),
      PlacesPage(repository: widget.placeRepository, favorites: widget.favoritesController, routingService: widget.routingService),
      SoufMapPage(repository: widget.placeRepository, favorites: widget.favoritesController, routingService: widget.routingService),
      FavoritesPage(repository: widget.placeRepository, favorites: widget.favoritesController, routingService: widget.routingService),
      CommunityPage(repository: widget.communityRepository),
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'وادنا',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
      home: _showWelcome
          ? WelcomePage(repository: widget.placeRepository, onContinue: _enterApp)
          : Scaffold(
              body: Stack(
                children: [
                  IndexedStack(index: _selectedIndex, children: pages),
                  if (_selectedIndex != 2)
                    PositionedDirectional(
                      top: MediaQuery.paddingOf(context).top + 6,
                      end: 12,
                      child: PopupMenuButton<_MenuAction>(
                        tooltip: 'الإعدادات',
                        onSelected: (action) {
                          if (action == _MenuAction.theme) {
                            _toggleTheme();
                          } else if (action == _MenuAction.privacy) {
                            _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                          } else {
                            _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const UpdateCenterPage()));
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: _MenuAction.theme, child: Row(children: [Icon(_themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined), const SizedBox(width: 10), const Text('تبديل المظهر')])),
                          const PopupMenuItem(value: _MenuAction.privacy, child: Row(children: [Icon(Icons.privacy_tip_outlined), SizedBox(width: 10), Text('سياسة الخصوصية')])),
                          const PopupMenuItem(value: _MenuAction.update, child: Row(children: [Icon(Icons.system_update_alt_rounded), SizedBox(width: 10), Text('تحديث التطبيق')])),
                        ],
                        child: const CircleAvatar(radius: 22, child: Icon(Icons.settings_outlined)),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
                  NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'المعالم'),
                  NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'الخريطة'),
                  NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'),
                  NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المجتمع'),
                ],
              ),
            ),
    );
  }
}

enum _MenuAction { theme, privacy, update }

/// Compatibility alias kept for existing integrations and smoke tests.
class SoufTourApp extends OuednaApp {
  const SoufTourApp({
    super.key,
    required super.placeRepository,
    required super.communityRepository,
    required super.tourGuideRepository,
    super.routingService,
    required super.favoritesController,
    required super.isBackendConfigured,
  });
}
