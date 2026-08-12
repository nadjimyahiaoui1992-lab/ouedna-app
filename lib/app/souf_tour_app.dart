import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/storage/favorites_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/favorites/presentation/favorites_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/map/presentation/souf_map_page.dart';
import '../features/places/domain/repositories/place_repository.dart';
import '../features/routing/domain/routing_service.dart';
import '../features/places/presentation/places_page.dart';
import '../features/tour_guide/domain/repositories/tour_guide_repository.dart';
import '../features/welcome/presentation/welcome_page.dart';

class SoufTourApp extends StatefulWidget {
  const SoufTourApp({
    super.key,
    required this.placeRepository,
    required this.tourGuideRepository,
    this.routingService,
    required this.favoritesController,
    required this.isBackendConfigured,
  });

  final PlaceRepository? placeRepository;
  final TourGuideRepository? tourGuideRepository;
  final RoutingService? routingService;
  final FavoritesController favoritesController;
  final bool isBackendConfigured;

  @override
  State<SoufTourApp> createState() => _SoufTourAppState();
}

class _SoufTourAppState extends State<SoufTourApp> {
  var _selectedIndex = 0;
  var _themeMode = ThemeMode.system;
  var _showWelcome = true;

  void _select(int index) => setState(() => _selectedIndex = index);
  void _toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

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
    ];

    return MaterialApp(
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
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 6,
                      left: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'تبديل الوضع الليلي',
                        onPressed: _toggleTheme,
                        icon: Icon(_themeMode == ThemeMode.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined),
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
                ],
              ),
            ),
    );
  }
}
