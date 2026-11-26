import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

void main() {
  final oneByOnePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  testWidgets(
    'renders circular photo with ClipOval and BoxFit.cover when crestUrl is valid local image',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('crest_widget_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final imgFile = File('${tempDir.path}/crest.png')
        ..writeAsBytesSync(oneByOnePng);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KickPulseTeamCrest(
              shortCode: 'RS',
              primaryColorHex: 0xFF2979FF,
              secondaryColorHex: 0xFFFFD600,
              crestUrl: imgFile.path,
              size: 56,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kick_pulse_team_crest_photo')),
        findsOneWidget,
      );
      expect(find.byType(ClipOval), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(
        find.byKey(const Key('kick_pulse_team_crest_fallback')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'falls back to circular monogram crest when crestUrl is null or file is missing',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KickPulseTeamCrest(
              shortCode: 'ATN',
              crestShape: TeamCrestShape.shield,
              crestUrl: null,
              size: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kick_pulse_team_crest_fallback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kick_pulse_team_crest_photo')),
        findsNothing,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KickPulseTeamCrest(
              shortCode: 'ATN',
              crestUrl: '/non/existent/path/crest.png',
              size: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kick_pulse_team_crest_fallback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kick_pulse_team_crest_photo')),
        findsNothing,
      );
    },
  );
}
