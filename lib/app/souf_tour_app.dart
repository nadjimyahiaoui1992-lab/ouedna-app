import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SoufTourApp extends StatefulWidget {
  const SoufTourApp({
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
  State<SoufTourApp> createState() => _SoufTourAppState();
}

class _SoufTourAppState extends State<SoufTourApp> {
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
    } catch (_) {
      // Browsing remains fully available if the host OS cannot deliver a link.
    }
  }

  void _handleDeepLink(Uri uri) {
    final placeId = _placeIdFromUri(uri);
    if (placeId == null || _openingPlaceId == placeId) return;
    setState(() {
      _showWelcome = false;
      _selectedIndex = 1;
      _openingPlaceId = placeId;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openSharedPlace(placeId));
  }

  int? _placeIdFromUri(Uri uri) {
    if (uri.scheme == 'souf360' && uri.host == 'place') {
      return uri.pathSegments.isEmpty
          ? null
          : int.tryParse(uri.pathSegments.first);
    }
    final isSoufWebsite =
        uri.scheme == 'https' && uri.host == 'souf360.vercel.app';
    if (isSoufWebsite &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'place') {
      return int.tryParse(uri.pathSegments[1]);
    }
    return null;
  }

  Future<void> _openSharedPlace(int placeId) async {
    final repository = widget.placeRepository;
    final navigator = _navigatorKey.currentState;
    if (repository == null || navigator == null) {
      _showLinkMessage('تعذر فتح المعلم لأن اتصال الدليل غير متاح حالياً.');
      return;
    }

    try {
      final place = await repository.getPublishedPlaceById(placeId);
      if (!mounted) return;
      if (place == null) {
        _showLinkMessage('هذا المعلم غير منشور أو لم يعد متاحاً.');
        return;
      }
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: repository,
            favorites: widget.favoritesController,
            routingService: widget.routingService,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showLinkMessage('تعذر فتح المعلم المُشارك. تحقق من اتصال الإنترنت.');
      }
    } finally {
      if (mounted && _openingPlaceId == placeId) {
        setState(() => _openingPlaceId = null);
      }
    }
  }

  void _showLinkMessage(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

  Future<void> _openPrivacyPolicy() async {
    final privacyUri = Uri.https('souf360.vercel.app', '/privacy');
    final opened =
        await launchUrl(privacyUri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showLinkMessage('تعذر فتح سياسة الخصوصية حالياً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        repository: widget.placeRepository,
        favorites: widget.favoritesController,
        tourGuideRepository: widget.tourGuideRepository,
        routingService: widget.routingService,
        onExplore: () => _select(1),
        onMap: () => _select(2),
      ),
      PlacesPage(
        repository: widget.placeRepository,
        favorites: widget.favoritesController,
        routingService: widget.routingService,
      ),
      SoufMapPage(
        repository: widget.placeRepository,
        favorites: widget.favoritesController,
        routingService: widget.routingService,
      ),
      FavoritesPage(
        repository: widget.placeRepository,
        favorites: widget.favoritesController,
        routingService: widget.routingService,
      ),
      CommunityPage(repository: widget.communityRepository),
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Souf 360',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _showWelcome
          ? WelcomePage(
              repository: widget.placeRepository,
              onContinue: () => setState(() => _showWelcome = false),
            )
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
                          } else {
                            _openPrivacyPolicy();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _MenuAction.theme,
                            child: Row(
                              children: [
                                Icon(_themeMode == ThemeMode.dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined),
                                const SizedBox(width: 10),
                                const Text('تبديل المظهر'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: _MenuAction.privacy,
                            child: Row(
                              children: [
                                Icon(Icons.privacy_tip_outlined),
                                SizedBox(width: 10),
                                Text('سياسة الخصوصية'),
                              ],
                            ),
                          ),
                        ],
                        child: const CircleAvatar(
                          radius: 22,
                          child: Icon(Icons.settings_outlined),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'الرئيسية',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'المعالم',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'الخريطة',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border),
                    selectedIcon: Icon(Icons.favorite),
                    label: 'المفضلة',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    selectedIcon: Icon(Icons.forum),
                    label: 'المجتمع',
                  ),
                ],
              ),
            ),
    );
  }
}

enum _MenuAction { theme, privacy }
