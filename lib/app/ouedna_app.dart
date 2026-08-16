import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/ouedna_localization.dart';
import '../core/storage/favorites_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/community/presentation/community_page.dart';
import '../features/favorites/presentation/favorites_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/map/presentation/souf_map_page.dart';
import '../features/notifications/data/ouedna_notification_service.dart';
import '../features/notifications/presentation/notification_bell.dart';
import '../features/notifications/presentation/notification_center_page.dart';
import '../features/places/domain/repositories/place_repository.dart';
import '../features/places/presentation/place_details_page.dart';
import '../features/places/presentation/places_page.dart';
import '../features/routing/domain/routing_service.dart';
import '../features/tour_guide/domain/repositories/tour_guide_repository.dart';
import '../features/updates/data/app_update_service.dart';
import '../features/updates/presentation/update_center_page.dart';
import '../core/widgets/entry_permissions_dialog.dart';
import '../features/welcome/presentation/privacy_policy_page.dart';
import '../features/welcome/presentation/welcome_page.dart';

class OuednaApp extends StatefulWidget {
  const OuednaApp({
    super.key,
    required this.placeRepository,
    required this.communityRepository,
    required this.tourGuideRepository,
    this.routingService,
    required this.favoritesController,
    required this.languageController,
    this.preferences,
    required this.isBackendConfigured,
  });

  final PlaceRepository? placeRepository;
  final CommunityRepository? communityRepository;
  final TourGuideRepository? tourGuideRepository;
  final RoutingService? routingService;
  final FavoritesController favoritesController;
  final AppLanguageController languageController;
  final SharedPreferences? preferences;
  final bool isBackendConfigured;

  @override
  State<OuednaApp> createState() => _OuednaAppState();
}

class _OuednaAppState extends State<OuednaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<void>? _updateActionSubscription;
  StreamSubscription<void>? _inboxActionSubscription;
  var _selectedIndex = 0;
  var _themeMode = ThemeMode.system;
  var _showWelcome = true;
  int? _openingPlaceId;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _updateActionSubscription?.cancel();
    _inboxActionSubscription?.cancel();
    OuednaNotificationService.instance.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final service = OuednaNotificationService.instance;
    await service.initialize(widget.languageController);
    if (!mounted) return;
    _updateActionSubscription = service.updateActions.listen((_) {
      _openUpdateCenter();
    });
    _inboxActionSubscription = service.inboxActions.listen((_) {
      _openNotificationCenter();
    });
  }

  void _openNotificationCenter() {
    if (!mounted) return;
    if (_showWelcome) setState(() => _showWelcome = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationCenterPage(
            repository: widget.placeRepository,
            favorites: widget.favoritesController,
            routingService: widget.routingService,
          ),
        ),
      );
    });
  }

  void _openUpdateCenter() {
    if (!mounted) return;
    if (_showWelcome) setState(() => _showWelcome = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const UpdateCenterPage()),
      );
    });
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openSharedPlace(placeId));
  }

  int? _placeIdFromUri(Uri uri) {
    if ((uri.scheme == 'ouedna' || uri.scheme == 'ouedna-v2') &&
        uri.host == 'place') {
      return uri.pathSegments.isEmpty
          ? null
          : int.tryParse(uri.pathSegments.first);
    }
    if (uri.scheme == 'https' &&
        uri.host == 'ouedna.vercel.app' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'place') {
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
      // A malformed or stale shared link must not interrupt the application.
    } finally {
      if (mounted && _openingPlaceId == placeId) {
        setState(() => _openingPlaceId = null);
      }
    }
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _enterApp() {
    setState(() => _showWelcome = false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybePromptForEntryPermissions();
      if (mounted) await _maybePromptForUpdate();
    });
  }

  Future<void> _maybePromptForEntryPermissions() async {
    final preferences = widget.preferences;
    if (preferences == null || !widget.isBackendConfigured) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastPrompt =
        preferences.getInt('ouedna.entry_permissions_prompted_at');
    const cooldown = Duration(days: 7);
    if (lastPrompt != null && now - lastPrompt < cooldown.inMilliseconds)
      return;
    await preferences.setInt('ouedna.entry_permissions_prompted_at', now);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EntryPermissionsDialog(
        languageController: widget.languageController,
      ),
    );
  }

  Future<void> _maybePromptForUpdate() async {
    final service = AppUpdateService();
    try {
      final update = await service.checkForUpdate();
      if (!mounted || update == null || !update.isUpdateAvailable) return;
      final strings = OuednaStrings.of(context);
      await showDialog<void>(
        context: context,
        barrierDismissible: !update.forceUpdate,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.system_update_alt_rounded, size: 38),
          title: Text(
            strings.text('update_available',
                values: {'version': update.latestVersion}),
          ),
          content: Text(
            update.releaseNotes?.isNotEmpty == true
                ? update.releaseNotes!
                : strings.text('update_description'),
          ),
          actions: [
            if (!update.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.text('later')),
              ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openUpdateCenter();
              },
              child: Text(strings.text('view_update')),
            ),
          ],
        ),
      );
    } catch (_) {
      // Updates are optional; network errors must not block tourism content.
    } finally {
      service.dispose();
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
        controller: widget.languageController,
        child: Builder(
          builder: (context) {
            final strings = OuednaStrings.of(context);
            final language = LanguageScope.languageOf(context);
            final pages = [
              HomePage(
                repository: widget.placeRepository,
                favorites: widget.favoritesController,
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
              title: strings.appName,
              debugShowCheckedModeBanner: false,
              locale: language.locale,
              supportedLocales: const [
                Locale('ar'),
                Locale('fr'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _themeMode,
              builder: (context, child) => Directionality(
                textDirection:
                    language.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
              home: _showWelcome
                  ? WelcomePage(
                      repository: widget.placeRepository,
                      onContinue: _enterApp,
                    )
                  : Scaffold(
                      body: Stack(
                        children: [
                          IndexedStack(index: _selectedIndex, children: pages),
                          if (_selectedIndex != 2 && widget.isBackendConfigured)
                            PositionedDirectional(
                              top: MediaQuery.paddingOf(context).top + 6,
                              end: 12,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DecoratedBox(
                                    decoration: const BoxDecoration(
                                      color: Color(0xEFFFFCF7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: NotificationBell(
                                      repository: widget.placeRepository,
                                      favorites: widget.favoritesController,
                                      routingService: widget.routingService,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const LanguageSelector(compact: true),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<_MenuAction>(
                                    tooltip: strings.text('settings'),
                                    onSelected: (action) {
                                      if (action == _MenuAction.theme) {
                                        _toggleTheme();
                                      } else if (action ==
                                          _MenuAction.privacy) {
                                        _navigatorKey.currentState?.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PrivacyPolicyPage(),
                                          ),
                                        );
                                      } else {
                                        _openUpdateCenter();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: _MenuAction.theme,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _themeMode == ThemeMode.dark
                                                  ? Icons.light_mode_outlined
                                                  : Icons.dark_mode_outlined,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(strings.text('change_theme')),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _MenuAction.privacy,
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.privacy_tip_outlined),
                                            const SizedBox(width: 10),
                                            Text(
                                                strings.text('privacy_policy')),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _MenuAction.update,
                                        child: Row(
                                          children: [
                                            const Icon(Icons
                                                .system_update_alt_rounded),
                                            const SizedBox(width: 10),
                                            Text(strings.text('app_update')),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: const CircleAvatar(
                                      radius: 22,
                                      child: Icon(Icons.settings_outlined),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      bottomNavigationBar: NavigationBar(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _select,
                        destinations: [
                          NavigationDestination(
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: const Icon(Icons.home),
                            label: strings.text('home'),
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.explore_outlined),
                            selectedIcon: const Icon(Icons.explore),
                            label: strings.text('places'),
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.map_outlined),
                            selectedIcon: const Icon(Icons.map),
                            label: strings.text('map'),
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.favorite_border),
                            selectedIcon: const Icon(Icons.favorite),
                            label: strings.text('favorites'),
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.forum_outlined),
                            selectedIcon: const Icon(Icons.forum),
                            label: strings.text('community'),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      );
}

enum _MenuAction { theme, privacy, update }
