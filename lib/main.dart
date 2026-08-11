import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/souf_tour_app.dart';
import 'core/config/app_config.dart';
import 'features/places/data/repositories/supabase_place_repository.dart';
import 'features/tour_guide/data/repositories/supabase_tour_guide_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabasePlaceRepository? placeRepository;
  SupabaseTourGuideRepository? tourGuideRepository;

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );

    final client = Supabase.instance.client;
    placeRepository = SupabasePlaceRepository(client);

    try {
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
      if (client.auth.currentSession != null) {
        tourGuideRepository = SupabaseTourGuideRepository(client);
      }
    } catch (_) {
      // Browsing Souf360 landmarks remains available when anonymous auth is off
      // or when a device is temporarily offline.
    }
  } catch (_) {
    // The app must always reach a usable screen, even if backend startup fails.
  }

  runApp(
    SoufTourApp(
      placeRepository: placeRepository,
      tourGuideRepository: tourGuideRepository,
      isBackendConfigured: placeRepository != null,
    ),
  );
}
