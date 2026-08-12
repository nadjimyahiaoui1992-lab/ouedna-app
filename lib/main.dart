import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/souf_tour_app.dart';
import 'core/config/app_config.dart';
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

  final preferences = await SharedPreferences.getInstance();
  final favoritesController = FavoritesController(preferences);
  PlaceRepository? placeRepository;
  CommunityRepository? communityRepository;
  TourGuideRepository? tourGuideRepository;
  final RoutingService routingService = OsrmRoutingService();

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

    try {
      // Always initialize the repository if we have a client.
      // The repository will handle authentication internally or via the function call.
      tourGuideRepository = SupabaseTourGuideRepository(client);

      if (client.auth.currentSession == null) {
        // Try to sign in anonymously to get a secure session for the AI Assistant.
        // If it fails (e.g. disabled in dashboard), the assistant will fallback
        // to a restricted mode or the function will handle it.
        await client.auth.signInAnonymously();
      }
    } catch (_) {
      // Browsing public content remains available.
    }
  } catch (_) {
    // The UI remains usable and exposes retry states if backend setup fails.
  }

  runApp(
    SoufTourApp(
      placeRepository: placeRepository,
      communityRepository: communityRepository,
      tourGuideRepository: tourGuideRepository,
      routingService: routingService,
      favoritesController: favoritesController,
      isBackendConfigured: placeRepository != null,
    ),
  );
}
