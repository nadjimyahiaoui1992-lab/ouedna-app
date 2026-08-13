import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souf_tour/app/souf_tour_app.dart';
import 'package:souf_tour/core/localization/ouedna_localization.dart';
import 'package:souf_tour/core/storage/favorites_controller.dart';

void main() {
  testWidgets('يفتح تطبيق Souf 360 للزائر دون اتصال', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final favorites = FavoritesController(preferences);
    final languageController = await AppLanguageController.load(preferences);

    await tester.pumpWidget(
      SoufTourApp(
        placeRepository: null,
        communityRepository: null,
        tourGuideRepository: null,
        favoritesController: favorites,
        languageController: languageController,
        isBackendConfigured: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دخول مباشر كزائر'), findsOneWidget);
    await tester.tap(find.text('دخول مباشر كزائر'));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المعالم'), findsOneWidget);
  });
}
