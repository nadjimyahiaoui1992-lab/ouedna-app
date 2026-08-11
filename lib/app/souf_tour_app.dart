import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/places/domain/repositories/place_repository.dart';
import '../features/tour_guide/domain/repositories/tour_guide_repository.dart';
import '../features/tour_guide/presentation/tour_guide_page.dart';

class SoufTourApp extends StatefulWidget {
  const SoufTourApp({
    super.key,
    required this.placeRepository,
    required this.tourGuideRepository,
    required this.isBackendConfigured,
  });

  final PlaceRepository? placeRepository;
  final TourGuideRepository? tourGuideRepository;
  final bool isBackendConfigured;

  @override
  State<SoufTourApp> createState() => _SoufTourAppState();
}

class _SoufTourAppState extends State<SoufTourApp> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExplorePage(
        placeRepository: widget.placeRepository,
        isBackendConfigured: widget.isBackendConfigured,
      ),
      TourGuidePage(repository: widget.tourGuideRepository),
      const ProfilePage(),
    ];

    return MaterialApp(
      title: 'سوف 360',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      home: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'استكشف',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'دليل سوف',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}
