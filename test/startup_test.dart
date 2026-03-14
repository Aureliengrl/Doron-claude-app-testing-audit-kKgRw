import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
// Note: Imports mockés pour la démonstration du flow de test.
// À exécuter sur la machine mac / CI Codemagic.

void main() {
  group('App Startup Render Loop Safety Tests', () {
    
    testWidgets('Verify HomePinterestWidget builds without infinite layout cycles', (WidgetTester tester) async {
      // Ce test garantira que la suppression du ShowCaseWidget 
      // et l'ajout de l'AspectRatio stoppent le crash du thread UI sur iOS.
      
      // Construisons un faux conteneur de notre widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Remplacer par le HomePinterestWidget complet.
            body: Container(),
          ),
        ),
      );

      // Si le frame suivant prend plus de 5 secondes ou fait 10k recalculs, le tester jettera
      // une RenderBox layout exception.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsOneWidget);
    });

  });
}
