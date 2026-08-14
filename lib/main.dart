import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/souf_tour_app.dart';
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

  PlaceRepository? placeRepository;
  CommunityRepository? communityRepository;
  TourGuideRepository? tourGuideRepository;
  final RoutingService routingService = OsrmRoutingService();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase Analytics et les notifications restent optionnels lorsque la
    // configuration Android Firebase n'est pas encore incluse.
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
    final client = Supabase.instance.client;
    placeRepository = CachedPlaceRepository(
      remote: SupabasePlaceRepository(client),
      preferences: preferences,
    );
    communityRepository = SupabaseCommunityRepository(client);
    tourGuideRepository = SupabaseTourGuideRepository(client);
    unawaited(
      AppMetricsService(preferences: preferences, client: client).recordStartup(
        localeCode: languageController.language.code,
      ),
    );
  } catch (_) {}

  runApp(
    OuednaApp(
      placeRepository: placeRepository,
      communityRepository: communityRepository,
      tourGuideRepository: tourGuideRepository,
      routingService: routingService,
      favoritesController: favoritesController,
      languageController: languageController,
      isBackendConfigured: placeRepository != null,
    ),
  );
}
