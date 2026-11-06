import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/daily_matches_tab_bar.dart';

void main() {
  testWidgets('renders yesterday, today and tomorrow tabs', (tester) async {
    MatchesDailyTab? selectedTab;
    final state = DailyMatchesDateState.today();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: DailyMatchesTabBar(
            dateState: state,
            onTabSelected: (tab) => selectedTab = tab,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_tab_yesterday')), findsOneWidget);
    expect(find.byKey(const Key('quick_tab_today')), findsOneWidget);
    expect(find.byKey(const Key('quick_tab_tomorrow')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_tab_yesterday')));
    await tester.pump();

    expect(selectedTab, equals(MatchesDailyTab.yesterday));
  });
}
