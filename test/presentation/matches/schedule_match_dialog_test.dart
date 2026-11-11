import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => true;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String prefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: prefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class _RecordingMatchesCatalogController
    extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _RecordingMatchesCatalogController() : super(const MatchesCatalogState());

  DateTime? lastScheduledStartTime;
  int scheduleCallCount = 0;

  @override
  Future<bool> scheduleMatch({
    required String matchId,
    required ChampionshipTournament tournament,
    required DateTime scheduledStartTime,
    required SportsVenue venue,
    required VenuePitch pitch,
    required MatchReferee referee,
    required UserRole userRole,
  }) async {
    scheduleCallCount++;
    lastScheduledStartTime = scheduledStartTime;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildDialogApp({
    required ChampionshipMatch match,
    required ChampionshipTournament tournament,
    required _RecordingMatchesCatalogController controller,
  }) {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(
          EnvironmentConfig.development(),
        ),
        localStorageRepositoryProvider.overrideWithValue(
          _FakeLocalStorageRepository(),
        ),
        connectivityRepositoryProvider.overrideWithValue(
          _FakeConnectivityRepository(),
        ),
        activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
        matchesCatalogControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        theme: KickPulseTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: ScheduleMatchDialog(match: match, tournament: tournament),
        ),
      ),
    );
  }

  group('ScheduleMatchDialog Present/Future Validation Tests', () {
    testWidgets(
      'date picker clamps firstDate to today even when tournament started in the past',
      (tester) async {
        final fixedNow = DateTime(2026, 11, 11, 10, 0);
        await withClock(Clock.fixed(fixedNow), () async {
          final tournament = ChampionshipTournament(
            id: 't-past-start',
            name: 'Liga en Curso',
            category: 'Libre',
            status: TournamentStatus.inProgress,
            format: TournamentFormat.league,
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 12, 20),
            updatedAt: DateTime(2026, 10, 1),
          );
          final match = ChampionshipMatch(
            id: 'm-1',
            tournamentId: tournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 't1',
            awayTeamId: 't2',
          );
          final controller = _RecordingMatchesCatalogController();

          await tester.pumpWidget(
            buildDialogApp(
              match: match,
              tournament: tournament,
              controller: controller,
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('pick_match_date_field')));
          await tester.pumpAndSettle();

          final datePicker = tester.widget<CalendarDatePicker>(
            find.byType(CalendarDatePicker),
          );
          expect(datePicker.firstDate, DateTime(2026, 11, 11));
          expect(datePicker.lastDate, DateTime(2026, 12, 20));
        });
      },
    );

    testWidgets(
      'allows scheduling in present minute and future, and blocks submitting a past time',
      (tester) async {
        var fakeCurrentTime = DateTime(2026, 11, 11, 10, 30, 20);
        await withClock(Clock(() => fakeCurrentTime), () async {
          final tournament = ChampionshipTournament(
            id: 't-active',
            name: 'Liga Presente',
            category: 'Libre',
            status: TournamentStatus.inProgress,
            format: TournamentFormat.league,
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 12, 20),
            updatedAt: DateTime(2026, 11, 1),
          );
          // Match previously had a past timestamp -> dialog clamps to presentMinute (10:30)
          final match = ChampionshipMatch(
            id: 'm-present',
            tournamentId: tournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 't1',
            awayTeamId: 't2',
            scheduledStartTime: DateTime(2026, 11, 9, 10, 30),
          );
          final controller = _RecordingMatchesCatalogController();

          await tester.pumpWidget(
            buildDialogApp(
              match: match,
              tournament: tournament,
              controller: controller,
            ),
          );
          await tester.pumpAndSettle();

          // Clock moves forward to 11:00 while dialog holds 11/11 10:30 -> past time error!
          fakeCurrentTime = DateTime(2026, 11, 11, 11, 0, 0);
          await tester.tap(
            find.byKey(const Key('confirm_schedule_match_button')),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(
              'No puedes programar un partido en una fecha u hora pasada.',
            ),
            findsOneWidget,
          );
          expect(controller.scheduleCallCount, 0);

          // Move clock back to present minute (10:30:55) -> scheduling succeeds!
          fakeCurrentTime = DateTime(2026, 11, 11, 10, 30, 55);
          await tester.tap(
            find.byKey(const Key('confirm_schedule_match_button')),
          );
          await tester.pumpAndSettle();

          expect(controller.scheduleCallCount, 1);
          expect(
            controller.lastScheduledStartTime,
            DateTime(2026, 11, 11, 10, 30),
          );
        });
      },
    );
  });
}
