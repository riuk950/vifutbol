import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:vifutbol/presentation/splash/lottie_splash_screen.dart';

void main() {
  testWidgets(
    'LottieSplashScreen renders Lottie animation then transitions to child',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LottieSplashScreen(
            child: Scaffold(body: Center(child: Text('Home Content'))),
          ),
        ),
      );

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('Home Content'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('Home Content'), findsOneWidget);
      expect(find.byType(Lottie), findsNothing);
    },
  );
}
