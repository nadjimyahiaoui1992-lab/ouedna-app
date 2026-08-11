import 'package:flutter_test/flutter_test.dart';
import 'package:souf_tour/app/souf_tour_app.dart';

void main() {
  testWidgets('affiche le parcours Souf360 sans connexion', (tester) async {
    await tester.pumpWidget(
      const SoufTourApp(
        placeRepository: null,
        tourGuideRepository: null,
        isBackendConfigured: false,
      ),
    );
    await tester.pump();

    expect(find.text('اكتشف سوف'), findsOneWidget);
    expect(find.text('دليل سوف'), findsOneWidget);
    expect(find.textContaining('تعذر الاتصال بمنصة Souf360'), findsOneWidget);
  });
}
