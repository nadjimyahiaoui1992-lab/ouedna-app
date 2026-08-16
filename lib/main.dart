import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/ouedna_app.dart';
import 'core/analytics/app_metrics_service.dart';
import 'core/config/app_config.dart';
import 'core/localization/ouedna_localization.dart';
import 'core/storage/favorites_controller.dart';
import 'features/community/data/repositories/supabase_community_repository.dart';
import 'features/community/domain/repositories/community_repository.dart';
import 'features/places/data/repositories/cached_place_repository.dart';
import 'features/places/data/repositories/supabase_place_repository.dart';
import 'features/places/domain/repositories/place_repository.dart';
import 'features/routing/data/osrm_routing_service.dart';
import 'features/routing/domain/routing_service.dart';
import 'features/tour_guide/data/repositories/supabase_tour_guide_repository.dart';
import 'features/tour_guide/domain/repositories/tour_guide_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (_) => const Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(
          color: Color(0xFFF8F7F2),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'تعذر عرض هذه الصفحة حالياً. أغلق التطبيق وافتحه من جديد، ثم تحقق من اتصال الإنترنت.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF163F3A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      );

  final preferences = await SharedPreferences.getInstance();
  final favoritesController = FavoritesController(preferences);
  final languageController = await AppLanguageController.load(preferences);
  final routingService = OsrmRoutingService();
  final backendFuture = _loadBackend(
    preferences: preferences,
    languageController: languageController,
  );

  runApp(
    _BootstrapApp(
      backendFuture: backendFuture,
      preferences: preferences,
      favoritesController: favoritesController,
      languageController: languageController,
      routingService: routingService,
    ),
  );
}

Future<_BackendBundle?> _loadBackend({
  required SharedPreferences preferences,
  required AppLanguageController languageController,
}) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional for browsing and local permission prompts.
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
    final client = Supabase.instance.client;
    unawaited(
      AppMetricsService(preferences: preferences, client: client).recordStartup(
        localeCode: languageController.language.code,
      ),
    );
    return _BackendBundle(
      placeRepository: CachedPlaceRepository(
        remote: SupabasePlaceRepository(client),
        preferences: preferences,
      ),
      communityRepository: SupabaseCommunityRepository(client),
      tourGuideRepository: SupabaseTourGuideRepository(client),
    );
  } catch (_) {
    return null;
  }
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp({
    required this.backendFuture,
    required this.preferences,
    required this.favoritesController,
    required this.languageController,
    required this.routingService,
  });

  final Future<_BackendBundle?> backendFuture;
  final SharedPreferences preferences;
  final FavoritesController favoritesController;
  final AppLanguageController languageController;
  final RoutingService routingService;

  @override
  Widget build(BuildContext context) => FutureBuilder<_BackendBundle?>(
        future: backendFuture,
        builder: (context, snapshot) {
          final backend = snapshot.data;
          return OuednaApp(
            placeRepository: backend?.placeRepository,
            communityRepository: backend?.communityRepository,
            tourGuideRepository: backend?.tourGuideRepository,
            routingService: routingService,
            favoritesController: favoritesController,
            languageController: languageController,
            preferences: preferences,
            isBackendConfigured: backend != null,
          );
        },
      );
}

class _BackendBundle {
  const _BackendBundle({
    required this.placeRepository,
    required this.communityRepository,
    required this.tourGuideRepository,
  });

  final PlaceRepository placeRepository;
  final CommunityRepository communityRepository;
  final TourGuideRepository tourGuideRepository;
}
