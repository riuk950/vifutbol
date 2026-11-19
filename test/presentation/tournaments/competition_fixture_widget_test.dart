import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_fixture_tab_view.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  _FakeLocalStorageRepository() {
    final venue = SportsVenue(
      id: 'venue-1',
      name: 'Sede Central',
      address: 'Calle 10 # 20-30',
      urbanReference: 'Parque Central',
      coordinate: const GeoCoordinate(latitude: 4.65, longitude: -74.08),
      pitches: const [
        VenuePitch(
          id: 'pitch-1',
          name: 'Cancha 1',
          surfaceType: PitchSurfaceType.syntheticGrass,
          format: PitchFormat.football11,
          capacity: 200,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        ),
      ],
      status: VenueOperationalStatus.active,
      updatedAt: DateTime(2026, 3, 1),
    );
    const referee = MatchReferee(
      id: 'ref-1',
      fullName: 'Wilmar Roldán',
      certificationLevel: 'FIFA',
      isActive: true,
    );
    _store[LocalVenuesRepository.storageKey] = jsonEncode([venue.toJson()]);
    _store[LocalTournamentMatchesRepository.refereesStorageKey] = jsonEncode([
      referee.toJson(),
    ]);
  }

  final Map<String, String> _store = <String, String>{};

  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async => _store.clear();
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
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

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           viewState: UiSuccessState(tournaments),
           tournaments: tournaments,
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

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
    final updated = state.matches.map((m) {
      if (m.id == matchId) {
        final durationMinutes = (tournament.rules.halfDurationMinutes * 2) + 15;
        final String? pitchName;
        if (venue != null && pitch != null) {
          pitchName = pitch.name.contains(venue.name)
              ? pitch.name
              : '${venue.name} - ${pitch.name}';
        } else {
          pitchName = venue?.name;
        }
        return m.copyWith(
          status: MatchStatus.scheduled,
          scheduledStartTime: scheduledStartTime,
          scheduledEndTime: scheduledStartTime.add(
            Duration(minutes: durationMinutes),
          ),
          venueId: venue?.id,
          pitchId: pitch?.id,
          pitchName: pitchName,
          refereeId: referee?.id,
          refereeName: referee?.fullName,
        );
      }
      return m;
    }).toList();
    state = state.copyWith(matches: updated);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createFixtureTestApp({
  required String tournamentId,
  List<ChampionshipMatch>? matches,
  List<TournamentTeam>? teams,
  List<ChampionshipTournament>? tournaments,
  UserRole role = UserRole.fan,
  FakeMatchesCatalogController? matchesController,
  double textScaleFactor = 1.0,
}) {
  final defaultTeams =
      teams ??
      [
        TournamentTeam(
          id: 'team-a',
          tournamentId: 't-1',
          name: 'Águilas Doradas',
          shortCode: 'AGU',
        ),
        TournamentTeam(
          id: 'team-b',
          tournamentId: 't-1',
          name: 'Tigres del Norte',
          shortCode: 'TIG',
        ),
        TournamentTeam(
          id: 'team-c',
          tournamentId: 't-1',
          name: 'Cóndores FC',
          shortCode: 'CON',
        ),
        TournamentTeam(
          id: 'team-d',
          tournamentId: 't-1',
          name: 'Halcones Urbanos',
          shortCode: 'HAL',
        ),
      ];

  final defaultMatches =
      matches ??
      [
        ChampionshipMatch(
          id: 'match-r1-1',
          tournamentId: 't-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 1,
          scheduledStartTime: DateTime(2026, 3, 10, 15, 0),
          pitchName: 'Cancha 1',
        ),
        ChampionshipMatch(
          id: 'match-r1-2',
          tournamentId: 't-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-c',
          awayTeamId: 'team-d',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 10, 17, 0),
          pitchName: 'Cancha 2',
        ),
        ChampionshipMatch(
          id: 'match-r2-1',
          tournamentId: 't-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-a',
          awayTeamId: 'team-c',
          status: MatchStatus.pendingSchedule,
        ),
      ];

  final defaultTournaments =
      tournaments ??
      [
        ChampionshipTournament(
          id: 't-1',
          name: 'Torneo Apertura 2026',
          category: 'Libre',
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 6, 30),
          rules: const TournamentRulesConfig(
            halfDurationMinutes: 45,
            leagueRounds: 1,
          ),
          updatedAt: DateTime(2026, 3, 1),
        ),
      ];

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
      activeUserRoleProvider.overrideWith((ref) => role),
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: defaultTournaments),
      ),
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: defaultTeams),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) =>
            matchesController ??
            FakeMatchesCatalogController(matches: defaultMatches),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        );
      },
      home: Scaffold(
        body: CompetitionFixtureTabView(tournamentId: tournamentId),
      ),
    ),
  );
}

void main() {
  group('CompetitionFixtureTabView', () {
    testWidgets(
      'renders full fixture grouped chronologically by rounds and shows logistics footers (US1, US2)',
      (tester) async {
        await tester.pumpWidget(createFixtureTestApp(tournamentId: 't-1'));
        await tester.pumpAndSettle();

        // Verify Fixture List is rendered
        expect(
          find.byKey(const Key('competition_detail_fixture_list')),
          findsOneWidget,
        );

        // Verify Round Headers
        expect(find.byKey(const Key('fixture_round_header_1')), findsOneWidget);
        expect(find.byKey(const Key('fixture_round_header_2')), findsOneWidget);
        expect(find.text('Jornada 1'), findsOneWidget);
        expect(find.text('Jornada 2'), findsOneWidget);

        // Verify Match Items under Round 1
        expect(
          find.byKey(const Key('fixture_match_item_match-r1-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fixture_match_item_match-r1-2')),
          findsOneWidget,
        );

        // Verify Match Item under Round 2
        expect(
          find.byKey(const Key('fixture_match_item_match-r2-1')),
          findsOneWidget,
        );

        // Verify Teams and Scores
        expect(
          find.text('Águilas Doradas'),
          findsNWidgets(2),
        ); // Played in r1 and r2
        expect(find.text('Tigres del Norte'), findsOneWidget);
        expect(find.text('2 - 1'), findsOneWidget);

        // Verify Logistics Footers
        expect(
          find.byKey(const Key('fixture_match_logistics_match-r1-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fixture_match_logistics_match-r1-2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fixture_match_logistics_match-r2-1')),
          findsOneWidget,
        );
        expect(find.text('Por programar'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a completed match card opens read-only Match Center modal bottom sheet for all roles',
      (tester) async {
        await tester.pumpWidget(
          createFixtureTestApp(tournamentId: 't-1', role: UserRole.organizer),
        );
        await tester.pumpAndSettle();

        final firstMatchFinder = find.byKey(
          const Key('fixture_match_item_match-r1-1'),
        );
        expect(firstMatchFinder, findsOneWidget);

        await tester.tap(firstMatchFinder);
        await tester.pumpAndSettle();

        // Verify Bottom Sheet Modal content (read-only), not ScheduleMatchDialog
        expect(
          find.text('Águilas Doradas vs Tigres del Norte'),
          findsOneWidget,
        );
        expect(find.text('Cancha 1'), findsOneWidget);
        expect(find.byType(ScheduleMatchDialog), findsNothing);
      },
    );

    testWidgets(
      'UserRole.fan tapping pending match opens read-only modal sheet instead of scheduling dialog',
      (tester) async {
        await tester.pumpWidget(
          createFixtureTestApp(tournamentId: 't-1', role: UserRole.fan),
        );
        await tester.pumpAndSettle();

        final pendingMatchFinder = find.byKey(
          const Key('fixture_match_item_match-r2-1'),
        );
        expect(pendingMatchFinder, findsOneWidget);

        await tester.tap(pendingMatchFinder);
        await tester.pumpAndSettle();

        // Modal sheet opens, ScheduleMatchDialog does NOT open
        expect(find.text('Águilas Doradas vs Cóndores FC'), findsOneWidget);
        expect(find.byType(ScheduleMatchDialog), findsNothing);
      },
    );

    testWidgets(
      'UserRole.organizer tapping pending match opens ScheduleMatchDialog (US1)',
      (tester) async {
        await tester.pumpWidget(
          createFixtureTestApp(tournamentId: 't-1', role: UserRole.organizer),
        );
        await tester.pumpAndSettle();

        final pendingMatchFinder = find.byKey(
          const Key('fixture_match_item_match-r2-1'),
        );
        expect(pendingMatchFinder, findsOneWidget);

        await tester.tap(pendingMatchFinder);
        await tester.pumpAndSettle();

        // ScheduleMatchDialog is opened
        expect(find.byType(ScheduleMatchDialog), findsOneWidget);
        expect(
          find.byKey(const Key('confirm_schedule_match_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('cancel_schedule_match_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UserRole.organizer schedules pending match, shows confirmation SnackBar, and updates logistics footer (US2)',
      (tester) async {
        final controller = FakeMatchesCatalogController(
          matches: [
            ChampionshipMatch(
              id: 'match-r2-1',
              tournamentId: 't-1',
              roundNumber: 2,
              roundName: 'Jornada 2',
              homeTeamId: 'team-a',
              awayTeamId: 'team-c',
              status: MatchStatus.pendingSchedule,
            ),
          ],
        );

        await tester.pumpWidget(
          createFixtureTestApp(
            tournamentId: 't-1',
            role: UserRole.organizer,
            matchesController: controller,
            matches: controller.state.matches,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Por programar'), findsOneWidget);

        // Tap pending match item to open dialog
        await tester.tap(
          find.byKey(const Key('fixture_match_item_match-r2-1')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ScheduleMatchDialog), findsOneWidget);

        // Confirm scheduling
        await tester.tap(
          find.byKey(const Key('confirm_schedule_match_button')),
        );
        await tester.pumpAndSettle();

        // Dialog is closed
        expect(find.byType(ScheduleMatchDialog), findsNothing);

        // Confirmation SnackBar appears
        expect(
          find.text('Programación del partido guardada exitosamente.'),
          findsOneWidget,
        );

        // Logistics footer is updated on the match card (no longer "Por programar")
        expect(find.text('Por programar'), findsNothing);
      },
    );

    testWidgets('renders empty state when tournament has no matches (US4)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createFixtureTestApp(tournamentId: 't-empty', matches: const []),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fixture_empty_matches_state')),
        findsOneWidget,
      );
      expect(find.text('Calendario en Preparación'), findsOneWidget);
      expect(
        find.text(
          'Esta competición aún no tiene partidos programados en su calendario oficial.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders without overflow on compact screen (320x640 at 130% text scale) (Polish)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createFixtureTestApp(
            tournamentId: 't-1',
            role: UserRole.organizer,
            textScaleFactor: 1.3,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('competition_detail_fixture_list')),
          findsOneWidget,
        );

        // Tap to open ScheduleMatchDialog on compact screen
        final matchFinder = find.byKey(
          const Key('fixture_match_item_match-r2-1'),
        );
        await tester.ensureVisible(matchFinder);
        await tester.pumpAndSettle();
        await tester.tap(matchFinder);
        await tester.pumpAndSettle();

        expect(find.byType(ScheduleMatchDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'GenerateFixtureConfirmationDialog renders Spanish regeneration warning and confirms once',
      (tester) async {
        int confirmCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es')],
            locale: const Locale('es'),
            theme: KickPulseTheme.darkTheme,
            home: Scaffold(
              body: GenerateFixtureConfirmationDialog(
                isRegeneration: true,
                onConfirm: () => confirmCalls++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Regenerar el fixture?'), findsOneWidget);
        expect(find.text('Regenerar Fixture'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('confirm_generate_fixture_button')),
        );
        await tester.pumpAndSettle();
        expect(confirmCalls, 1);
      },
    );
  });
}
