import 'package:flutter_test/flutter_test.dart';
import 'package:souf_tour/app/souf_tour_app.dart';

void main() {
  testWidgets('affiche le parcours d’exploration sans configuration distante',
      (tester) async {
    await tester.pumpWidget(
      const SoufTourApp(
        placeRepository: null,
        tourGuideRepository: null,
        isBackendConfigured: false,
      ),
    );
    await tester.pump();

    expect(find.text('El Oued, autrement'), findsOneWidget);
    expect(find.text('Guide IA'), findsOneWidget);
    expect(find.textContaining('Mode démonstration'), findsOneWidget);
  });
}
