import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souf_tour/app/souf_tour_app.dart';
import 'package:souf_tour/core/storage/favorites_controller.dart';

void main() {
  testWidgets('يعرض تطبيق Souf 360 حالة عدم الاتصال بشكل آمن', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final favorites = FavoritesController(preferences);

    await tester.pumpWidget(
      SoufTourApp(
        placeRepository: null,
        tourGuideRepository: null,
        favoritesController: favorites,
        isBackendConfigured: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
