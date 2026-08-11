import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/souf_tour_app.dart';
import 'core/config/app_config.dart';
import 'core/storage/favorites_controller.dart';
import 'features/places/data/repositories/cached_place_repository.dart';
import 'features/places/data/repositories/supabase_place_repository.dart';
import 'features/places/domain/repositories/place_repository.dart';
import 'features/routing/data/supabase_routing_service.dart';
import 'features/routing/domain/routing_service.dart';
import 'features/tour_guide/data/repositories/supabase_tour_guide_repository.dart';
import 'features/tour_guide/domain/repositories/tour_guide_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final favoritesController = FavoritesController(preferences);
  PlaceRepository? placeRepository;
  TourGuideRepository? tourGuideRepository;
  RoutingService? routingService;

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

    try {
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
      if (client.auth.currentSession != null) {
        tourGuideRepository = SupabaseTourGuideRepository(client);
        routingService = SupabaseRoutingService(client);
      }
    } catch (_) {
      // Browsing public Souf360 content does not depend on anonymous login.
    }
  } catch (_) {
    // The UI remains usable and exposes retry states if backend setup fails.
  }

  runApp(
    SoufTourApp(
      placeRepository: placeRepository,
      tourGuideRepository: tourGuideRepository,
      routingService: routingService,
      favoritesController: favoritesController,
      isBackendConfigured: placeRepository != null,
    ),
  );
}
