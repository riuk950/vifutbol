import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';
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
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  _FakeLocalStorageRepository() {
    final venue = SportsVenue(
      id: 'venue-1',
      name: 'Sede Test',
      address: 'Calle 10 # 20-30',
      urbanReference: 'Centro',
      coordinate: const GeoCoordinate(latitude: 4.65, longitude: -74.08),
      pitches: const [
        VenuePitch(
          id: 'pitch-1',
          name: 'Cancha 1',
          surfaceType: PitchSurfaceType.syntheticGrass,
          format: PitchFormat.football11,
          capacity: 100,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        ),
      ],
      status: VenueOperationalStatus.active,
      updatedAt: DateTime(2026, 11, 1),
    );
    const referee = MatchReferee(
      id: 'ref-1',
      fullName: 'Árbitro Test',
      certificationLevel: 'FIFA',
      isActive: true,
    );
    _store[LocalVenuesRepository.storageKey] = jsonEncode([venue.toJson()]);
    _store[LocalTournamentMatchesRepository.refereesStorageKey] = jsonEncode([
      referee.toJson(),
    ]);
  }

  final Map<String, String> _store = {};

  @override
  bool get isUsingFallbackMemory => true;
  @override
  Future<void> clearNamespace() async => _store.clear();
  @override
  Future<LocalStorageStatus> initialize(String prefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: prefix);
  @override
  Future<String?> readString(String key) async => _store[key];
  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }
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
  SportsVenue? lastVenue;
  VenuePitch? lastPitch;
  MatchReferee? lastReferee;
  int scheduleCallCount = 0;

  @override
  Future<bool> scheduleMatch({
    required String matchId,
    required ChampionshipTournament tournament,
    required DateTime scheduledStartTime,
    SportsVenue? venue,
    VenuePitch? pitch,
    MatchReferee? referee,
    required UserRole userRole,
  }) async {
    scheduleCallCount++;
    lastScheduledStartTime = scheduledStartTime;
    lastVenue = venue;
    lastPitch = pitch;
    lastReferee = referee;
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
          ...GlobalMaterialLocalizations.delegates,
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
      'date picker allows todayColombia through 2100-12-31 without tournament start/end caps',
      (tester) async {
        final fixedNow = ColombiaTimeUtils.fromColombiaWallClock(
          2026,
          11,
          11,
          10,
          0,
        );
        await withClock(Clock.fixed(fixedNow), () async {
          final tournament = ChampionshipTournament(
            id: 't-past-start',
            name: 'Liga en Curso',
            category: 'Libre',
            status: TournamentStatus.inProgress,
            format: TournamentFormat.league,
            startDate: DateTime(2026, 12, 1),
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

          // Button renders 12h AM/PM format
          expect(find.text('10:00 AM'), findsOneWidget);

          await tester.tap(find.byKey(const Key('pick_match_date_field')));
          await tester.pumpAndSettle();

          final datePicker = tester.widget<CalendarDatePicker>(
            find.byType(CalendarDatePicker),
          );
          expect(datePicker.firstDate, DateTime(2026, 11, 11));
          expect(datePicker.lastDate, DateTime(2100, 12, 31));
        });
      },
    );

    testWidgets(
      'forces 12-hour AM/PM time picker even when device prefers 24-hour format',
      (tester) async {
        final fixedNow = ColombiaTimeUtils.fromColombiaWallClock(
          2026,
          11,
          11,
          15,
          30,
        );
        await withClock(Clock.fixed(fixedNow), () async {
          final tournament = ChampionshipTournament(
            id: 't-12h',
            name: 'Liga 12h',
            category: 'Libre',
            status: TournamentStatus.openRegistration,
            format: TournamentFormat.league,
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 12, 20),
            updatedAt: DateTime(2026, 11, 1),
          );
          final match = ChampionshipMatch(
            id: 'm-12h',
            tournamentId: tournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 't1',
            awayTeamId: 't2',
          );
          final controller = _RecordingMatchesCatalogController();

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: true),
              child: buildDialogApp(
                match: match,
                tournament: tournament,
                controller: controller,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('03:30 PM'), findsOneWidget);

          await tester.tap(find.byKey(const Key('pick_match_time_field')));
          await tester.pumpAndSettle();

          // TimePickerDialog must receive alwaysUse24HourFormat: false regardless of device 24h setting
          final pickerContext = tester.element(find.byType(TimePickerDialog));
          expect(MediaQuery.of(pickerContext).alwaysUse24HourFormat, isFalse);
        });
      },
    );

    testWidgets(
      'allows scheduling in present minute and future in Colombia time, and blocks submitting a past time',
      (tester) async {
        var fakeCurrentTime = ColombiaTimeUtils.fromColombiaWallClock(
          2026,
          11,
          11,
          10,
          30,
          20,
        );
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
          // Match previously had a past timestamp -> dialog clamps to presentMinute (10:30 AM Colombia)
          final match = ChampionshipMatch(
            id: 'm-present',
            tournamentId: tournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 't1',
            awayTeamId: 't2',
            scheduledStartTime: ColombiaTimeUtils.fromColombiaWallClock(
              2026,
              11,
              9,
              10,
              30,
            ),
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

          // Clock moves forward to 11:00 AM Colombia while dialog holds 11/11 10:30 AM -> past time error!
          fakeCurrentTime = ColombiaTimeUtils.fromColombiaWallClock(
            2026,
            11,
            11,
            11,
            0,
            0,
          );
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

          // Move clock back to present minute (10:30:55 AM Colombia) -> scheduling succeeds with UTC instant!
          fakeCurrentTime = ColombiaTimeUtils.fromColombiaWallClock(
            2026,
            11,
            11,
            10,
            30,
            55,
          );
          await tester.tap(
            find.byKey(const Key('confirm_schedule_match_button')),
          );
          await tester.pumpAndSettle();

          expect(controller.scheduleCallCount, 1);
          expect(
            controller.lastScheduledStartTime,
            ColombiaTimeUtils.fromColombiaWallClock(2026, 11, 11, 10, 30),
          );
        });
      },
    );

    testWidgets(
      'allows scheduling with date and time only when optional venue, pitch, and referee are Por definir',
      (tester) async {
        final fakeNow = DateTime(2026, 11, 10, 9, 0);
        await withClock(Clock.fixed(fakeNow), () async {
          final emptyStorage = _FakeLocalStorageRepository();
          await emptyStorage.writeString(LocalVenuesRepository.storageKey, '[]');
          await emptyStorage.writeString(
            LocalTournamentMatchesRepository.refereesStorageKey,
            '[]',
          );

          final tournament = ChampionshipTournament(
            id: 't-opt',
            name: 'Liga Opcional',
            category: 'Libre',
            status: TournamentStatus.openRegistration,
            format: TournamentFormat.league,
            startDate: DateTime(2026, 11, 1),
            endDate: DateTime(2026, 12, 20),
            updatedAt: DateTime(2026, 11, 1),
          );
          final match = ChampionshipMatch(
            id: 'm-opt',
            tournamentId: tournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 't1',
            awayTeamId: 't2',
          );
          final controller = _RecordingMatchesCatalogController();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                environmentConfigProvider.overrideWithValue(
                  EnvironmentConfig.development(),
                ),
                localStorageRepositoryProvider.overrideWithValue(emptyStorage),
                connectivityRepositoryProvider.overrideWithValue(
                  _FakeConnectivityRepository(),
                ),
                activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
                matchesCatalogControllerProvider.overrideWith((ref) => controller),
              ],
              child: MaterialApp(
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                supportedLocales: const [Locale('es')],
                locale: const Locale('es'),
                theme: KickPulseTheme.darkTheme,
                home: Scaffold(
                  body: ScheduleMatchDialog(
                    match: match,
                    tournament: tournament,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Por definir'), findsNWidgets(2));

          await tester.tap(
            find.byKey(const Key('confirm_schedule_match_button')),
          );
          await tester.pumpAndSettle();

          expect(controller.scheduleCallCount, 1);
          expect(controller.lastVenue, isNull);
          expect(controller.lastPitch, isNull);
          expect(controller.lastReferee, isNull);
        });
      },
    );
  });
}
