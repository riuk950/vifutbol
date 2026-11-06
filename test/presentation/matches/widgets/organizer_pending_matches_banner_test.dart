import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/presentation/matches/widgets/organizer_pending_matches_banner.dart';

void main() {
  testWidgets('renders banner when there are pending matches', (tester) async {
    bool scheduleTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizerPendingMatchesBanner(
            pendingMatchesCount: 3,
            unseededTournamentsCount: 1,
            onScheduleTap: () => scheduleTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('3 partidos pendientes de programar fecha y sede'), findsOneWidget);
    expect(find.byKey(const Key('organizer_schedule_pending_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('organizer_schedule_pending_button')));
    await tester.pump();

    expect(scheduleTapped, isTrue);
  });

  testWidgets('renders empty space when counts are 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrganizerPendingMatchesBanner(
            pendingMatchesCount: 0,
            unseededTournamentsCount: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ElevatedButton), findsNothing);
  });
}
