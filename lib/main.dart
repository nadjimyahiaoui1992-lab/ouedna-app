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

  if (AppConfig.isSupabaseConfigured) {
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
    } on AuthException {
      // The application remains readable if anonymous sign-ins are disabled.
      // The guide tab explains that it is unavailable until the server is configured.
    }
  }

  runApp(
    SoufTourApp(
      placeRepository: placeRepository,
      tourGuideRepository: tourGuideRepository,
      isBackendConfigured: AppConfig.isSupabaseConfigured,
    ),
  );
}
