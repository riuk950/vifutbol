import 'dart:async';

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
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/competition_detail_screen.dart';
import 'package:vifutbol/presentation/tournaments/widgets/add_teams_to_competition_modal.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
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

class _InMemoryTeamsRepository implements TeamsRepository {
  final List<TournamentTeam> _teams;
  Completer<void>? saveBlocker;
  int saveCalls = 0;
  int loadCalls = 0;

  _InMemoryTeamsRepository(List<TournamentTeam> initialTeams)
    : _teams = List<TournamentTeam>.from(initialTeams);

  @override
  Future<List<TournamentTeam>> loadTeams() async {
    loadCalls++;
    return List<TournamentTeam>.unmodifiable(_teams);
  }

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    return _teams.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async {
    saveCalls++;
    if (saveBlocker != null) {
      await saveBlocker!.future;
    }
    final index = _teams.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      _teams[index] = team;
    } else {
      _teams.add(team);
    }
    return team;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    _teams.removeWhere((t) => t.id == teamId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController(List<ChampionshipTournament> tournaments)
    : super(
        TournamentsCatalogState(
          viewState: UiSuccessState<List<ChampionshipTournament>>(tournaments),
          tournaments: tournaments,
        ),
      );

  @override
  Future<void> loadCatalog() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController([List<ChampionshipMatch> matches = const []])
    : super(MatchesCatalogState(matches: matches));

  @override
  Future<void> loadTournamentMatches(String tournamentId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChampionshipTournament _createTournament({
  String id = 'tourn-current',
  TournamentFormat format = TournamentFormat.league,
  int groupCount = 2,
}) {
  return ChampionshipTournament(
    id: id,
    name: 'Copa Verano 2026',
    category: 'Libre',
    status: TournamentStatus.openRegistration,
    format: format,
    rules: TournamentRulesConfig(
      groupStageConfig: GroupStageConfig(groupCount: groupCount),
    ),
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}

Widget _buildTestHost({
  required ChampionshipTournament tournament,
  required _InMemoryTeamsRepository teamsRepo,
  Widget? home,
}) {
  final useCase = ManageTeamsEligibilityUseCase(teamsRepo);
  final teamsController = TeamsController(
    teamsRepository: teamsRepo,
    manageTeamsEligibilityUseCase: useCase,
  );

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
      tournamentsControllerProvider.overrideWith(
        (ref) => _FakeTournamentsController([tournament]),
      ),
      teamsRepositoryProvider.overrideWithValue(teamsRepo),
      teamsControllerProvider.overrideWith((ref) => teamsController),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => _FakeMatchesCatalogController(),
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
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: home ?? CompetitionDetailScreen(tournamentId: tournament.id),
    ),
  );
}

void main() {
  group('AddTeamsToCompetitionModal Search & Catalog Tests (US2)', () {
    testWidgets(
      'opens from FAB Agregar Equipos, deduplicates catalog alphabetically, and filters case/diacritic-insensitively',
      (tester) async {
        final tournament = _createTournament();
        final teamsRepo = _InMemoryTeamsRepository([
          TournamentTeam(
            id: 'cat-aguilas',
            tournamentId: 'other-1',
            name: 'Águilas FC',
            shortCode: 'AGU',
            updatedAt: DateTime(2026, 5, 1),
          ),
          TournamentTeam(
            id: 'cat-atletico-empty',
            tournamentId: 'other-1',
            name: 'Atlético del Sur',
            shortCode: 'ADS',
            players: const [],
            updatedAt: DateTime(2026, 4, 1),
          ),
          TournamentTeam(
            id: 'cat-atletico-rich',
            tournamentId: 'other-2',
            name: 'Atlético del Sur',
            shortCode: 'ADS',
            players: const [
              RegisteredPlayer(
                id: 'p1',
                fullName: 'Juan Perez',
                documentId: 'DOC-1',
                shirtNumber: 10,
                position: PlayerPosition.midfielder,
              ),
            ],
            updatedAt: DateTime(2026, 6, 1),
          ),
          TournamentTeam(
            id: 'cat-tigres',
            tournamentId: 'other-2',
            name: 'Tigres FC',
            shortCode: 'TIG',
            updatedAt: DateTime(2026, 5, 15),
          ),
        ]);

        await tester.pumpWidget(
          _buildTestHost(tournament: tournament, teamsRepo: teamsRepo),
        );
        await tester.pumpAndSettle();

        // Open FAB menu -> tap Agregar Equipos
        await tester.tap(find.byKey(const Key('competition_detail_fab_menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('competition_detail_fab_add_team')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('add_teams_modal')), findsOneWidget);
        expect(find.byKey(const Key('add_teams_search_field')), findsOneWidget);

        // Deduplicated: only richer Atlético del Sur shown alongside Águilas FC and Tigres FC
        expect(
          find.byKey(const Key('add_teams_catalog_item_cat-atletico-rich')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_teams_catalog_item_cat-atletico-empty')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('add_teams_catalog_item_cat-aguilas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('add_teams_catalog_item_cat-tigres')),
          findsOneWidget,
        );

        // Filter ignoring tildes and case: "atletico" -> matches "Atlético del Sur"
        await tester.enterText(
          find.byKey(const Key('add_teams_search_field')),
          'atletico',
        );
        await tester.pump();
        expect(find.text('Atlético del Sur'), findsOneWidget);
        expect(find.text('Águilas FC'), findsNothing);
        expect(find.text('Tigres FC'), findsNothing);

        // Filter uppercase without tilde: "AGUILAS" -> matches "Águilas FC"
        await tester.enterText(
          find.byKey(const Key('add_teams_search_field')),
          'AGUILAS',
        );
        await tester.pump();
        expect(find.text('Águilas FC'), findsOneWidget);
        expect(find.text('Atlético del Sur'), findsNothing);

        // Filter by shortCode
        await tester.enterText(
          find.byKey(const Key('add_teams_search_field')),
          'tig',
        );
        await tester.pump();
        expect(find.text('Tigres FC'), findsOneWidget);

        // Non-matching query displays empty search state and clear button
        await tester.enterText(
          find.byKey(const Key('add_teams_search_field')),
          'equipo inexistente',
        );
        await tester.pump();
        expect(
          find.byKey(const Key('add_teams_empty_search_state')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('add_teams_clear_filter_button')),
        );
        await tester.pump();
        expect(find.text('Águilas FC'), findsOneWidget);
        expect(find.text('Atlético del Sur'), findsOneWidget);
        expect(find.text('Tigres FC'), findsOneWidget);

        // Closing modal discards filter without adding teams
        await tester.tap(find.byKey(const Key('add_teams_modal_close_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('add_teams_modal')), findsNothing);
        final currentEnrolled = await teamsRepo.loadTeamsForTournament(
          tournament.id,
        );
        expect(currentEnrolled, isEmpty);
      },
    );

    testWidgets(
      'shows empty catalog state with exact governance copy and zero creation buttons (US2)',
      (tester) async {
        final tournament = _createTournament();
        final teamsRepo = _InMemoryTeamsRepository(const []);

        await tester.pumpWidget(
          _buildTestHost(
            tournament: tournament,
            teamsRepo: teamsRepo,
            home: Scaffold(
              body: AddTeamsToCompetitionModal(tournament: tournament),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('add_teams_empty_catalog_state')),
          findsOneWidget,
        );
        expect(
          find.text(
            'No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato.',
          ),
          findsOneWidget,
        );

        // Strictly verify absence of any team creation/registration buttons or forms
        expect(find.textContaining('Crear'), findsNothing);
        expect(find.textContaining('Registrar'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);
      },
    );

    testWidgets(
      'triggers loadTeams() on open, lists standalone clubs, renders category with fallback and conditional coach (US1)',
      (tester) async {
        final tournament = _createTournament();
        final teamsRepo = _InMemoryTeamsRepository([
          TournamentTeam(
            id: 'standalone-millos',
            tournamentId: '',
            name: 'Millonarios FC',
            shortCode: 'MFC',
            categoryLabel: null,
            coachName: 'Alberto Gamero',
            updatedAt: DateTime(2026, 11, 1),
          ),
          TournamentTeam(
            id: 'other-santafe',
            tournamentId: 'other-tourn-99',
            name: 'Independiente Santa Fe',
            shortCode: 'ISF',
            categoryLabel: 'Sub-20',
            coachName: null,
            updatedAt: DateTime(2026, 11, 2),
          ),
        ]);

        await tester.pumpWidget(
          _buildTestHost(
            tournament: tournament,
            teamsRepo: teamsRepo,
            home: Scaffold(
              body: AddTeamsToCompetitionModal(tournament: tournament),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify loadTeams was triggered on open
        expect(teamsRepo.loadCalls, greaterThanOrEqualTo(1));

        // 2. Verify standalone club Millonarios FC is listed
        expect(find.text('Millonarios FC'), findsOneWidget);
        // Has category fallback: "Categoría libre"
        expect(find.textContaining('Categoría libre'), findsOneWidget);
        // Has coach line: "DT: Alberto Gamero"
        expect(
          find.byKey(const Key('add_teams_coach_meta_standalone-millos')),
          findsOneWidget,
        );
        expect(find.text('DT: Alberto Gamero'), findsOneWidget);

        // 3. Verify cross-tournament club Santa Fe is listed
        expect(find.text('Independiente Santa Fe'), findsOneWidget);
        // Has assigned category: "Sub-20"
        expect(find.textContaining('Sub-20'), findsOneWidget);
        // Coach is null -> coach line MUST be omitted completely
        expect(
          find.byKey(const Key('add_teams_coach_meta_other-santafe')),
          findsNothing,
        );

        // 4. Enroll standalone club
        final enrollBtnFinder = find.byKey(
          const Key('add_teams_action_button_standalone-millos'),
        );
        await tester.tap(enrollBtnFinder);
        await tester.pumpAndSettle();

        // Modal stays open
        expect(find.byKey(const Key('add_teams_modal')), findsOneWidget);

        // Verify newly enrolled in repository is in pendingVerification
        final tournamentTeams = await teamsRepo.loadTeamsForTournament(
          tournament.id,
        );
        expect(tournamentTeams.length, 1);
        final newlyEnrolled = tournamentTeams.firstWhere(
          (t) => t.name == 'Millonarios FC',
        );
        expect(
          newlyEnrolled.eligibilityStatus,
          TeamEligibilityStatus.pendingVerification,
        );
        expect(newlyEnrolled.coachName, 'Alberto Gamero');

        // Button transitions to Inscrito (disabled)
        expect(
          find.byKey(Key('add_teams_enrolled_badge_${newlyEnrolled.id}')),
          findsOneWidget,
        );
        final enrolledBtn = tester.widget<Widget>(
          find.byKey(Key('add_teams_action_button_${newlyEnrolled.id}')),
        );
        expect((enrolledBtn as dynamic).onPressed, isNull);
      },
    );
  });

  group('AddTeamsToCompetitionModal Enrollment & Integrity Tests (US3)', () {
    testWidgets(
      'marks enrolled teams as Inscrito disabled, enrolls available team in pendingVerification keeping modal open & search preserved, and updates Equipos tab reactively',
      (tester) async {
        final tournament = _createTournament();
        final teamsRepo = _InMemoryTeamsRepository([
          // Already enrolled without tilde
          TournamentTeam(
            id: 'enrolled-aguilas',
            tournamentId: tournament.id,
            name: 'Aguilas FC',
            shortCode: 'AGU',
            eligibilityStatus: TeamEligibilityStatus.eligible,
            players: const [
              RegisteredPlayer(
                id: 'ep-1',
                fullName: 'Jugador Conflicto',
                documentId: 'DUP-999',
                shirtNumber: 8,
                position: PlayerPosition.midfielder,
                isEligible: true,
              ),
            ],
          ),
          // Catalog entry matching normalized name ("Águilas FC" vs "Aguilas FC")
          TournamentTeam(
            id: 'cat-aguilas',
            tournamentId: 'other-1',
            name: 'Águilas FC',
            shortCode: 'AGU',
          ),
          // Available catalog team with 1 conflicting and 1 clean player
          TournamentTeam(
            id: 'cat-atletico',
            tournamentId: 'other-1',
            name: 'Atlético del Sur',
            shortCode: 'ADS',
            players: const [
              RegisteredPlayer(
                id: 'p-dup',
                fullName: 'Jugador Conflicto',
                documentId: 'dup-999',
                shirtNumber: 8,
                position: PlayerPosition.midfielder,
                isEligible: true,
              ),
              RegisteredPlayer(
                id: 'p-ok',
                fullName: 'Pedro Limpio',
                documentId: 'OK-100',
                shirtNumber: 11,
                position: PlayerPosition.forward,
                isEligible: true,
              ),
            ],
          ),
        ]);

        await tester.pumpWidget(
          _buildTestHost(tournament: tournament, teamsRepo: teamsRepo),
        );
        await tester.pumpAndSettle();

        // Switch to Equipos tab first so we verify reactive update underneath
        await tester.tap(find.byKey(const Key('competition_detail_tab_teams')));
        await tester.pumpAndSettle();
        expect(find.text('Equipos Inscritos (1)'), findsOneWidget);

        // Open modal via FAB Menu
        await tester.tap(find.byKey(const Key('competition_detail_fab_menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('competition_detail_fab_add_team')),
        );
        await tester.pumpAndSettle();

        // Enrolled match shows Inscrito badge and disabled button
        expect(
          find.byKey(const Key('add_teams_enrolled_badge_enrolled-aguilas')),
          findsOneWidget,
        );
        final enrolledBtn = tester.widget<Widget>(
          find.byKey(const Key('add_teams_action_button_enrolled-aguilas')),
        );
        expect((enrolledBtn as dynamic).onPressed, isNull);

        // Type search query "atletico" and enroll Atlético del Sur
        await tester.enterText(
          find.byKey(const Key('add_teams_search_field')),
          'atletico',
        );
        await tester.pump();

        await tester.tap(
          find.byKey(const Key('add_teams_action_button_cat-atletico')),
        );
        await tester.pumpAndSettle();

        // Modal remains open and preserves search text
        expect(find.byKey(const Key('add_teams_modal')), findsOneWidget);
        final searchField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('add_teams_search_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(searchField.controller?.text, 'atletico');

        // Feedback banner mentions omitted conflicting player
        expect(
          find.byKey(const Key('add_teams_feedback_banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('omitió 1 jugador ya inscrito'),
          findsOneWidget,
        );

        // Persisted team has pendingVerification status and only non-conflicting pending player
        final tournamentTeams = await teamsRepo.loadTeamsForTournament(
          tournament.id,
        );
        expect(tournamentTeams.length, 2);
        final newlyEnrolled = tournamentTeams.firstWhere(
          (t) => t.name == 'Atlético del Sur',
        );
        expect(
          newlyEnrolled.eligibilityStatus,
          TeamEligibilityStatus.pendingVerification,
        );
        expect(newlyEnrolled.players.length, 1);
        expect(newlyEnrolled.players.first.documentId, 'OK-100');
        expect(newlyEnrolled.players.first.isEligible, isFalse);

        // Close modal and verify Equipos tab updated reactively
        await tester.tap(find.byKey(const Key('add_teams_modal_close_button')));
        await tester.pumpAndSettle();
        expect(find.text('Equipos Inscritos (2)'), findsOneWidget);
        expect(find.text('Atlético del Sur'), findsOneWidget);
      },
    );

    testWidgets(
      'blocks rapid double taps on Agregar while enrollment is in flight',
      (tester) async {
        final tournament = _createTournament();
        final teamsRepo = _InMemoryTeamsRepository([
          TournamentTeam(
            id: 'cat-tigres',
            tournamentId: 'other-1',
            name: 'Tigres FC',
            shortCode: 'TIG',
          ),
        ]);

        await tester.pumpWidget(
          _buildTestHost(
            tournament: tournament,
            teamsRepo: teamsRepo,
            home: Scaffold(
              body: AddTeamsToCompetitionModal(tournament: tournament),
            ),
          ),
        );
        await tester.pumpAndSettle();

        teamsRepo.saveBlocker = Completer<void>();

        final addBtnFinder = find.byKey(
          const Key('add_teams_action_button_cat-tigres'),
        );
        await tester.tap(addBtnFinder);
        await tester.pump();

        // Second rapid tap while saving is in progress must be ignored
        await tester.tap(addBtnFinder, warnIfMissed: false);
        await tester.pump();

        teamsRepo.saveBlocker!.complete();
        await tester.pumpAndSettle();

        expect(teamsRepo.saveCalls, 1);
        final tournamentTeams = await teamsRepo.loadTeamsForTournament(
          tournament.id,
        );
        expect(tournamentTeams.length, 1);
      },
    );

    testWidgets(
      'renders without overflow on compact viewport (320x640 at 130% text scale) and auto-assigns least-populated group in mixed format',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mixedTournament = _createTournament(
          id: 'tourn-mixed',
          format: TournamentFormat.mixedGroupsAndKnockout,
          groupCount: 2,
        );
        final teamsRepo = _InMemoryTeamsRepository([
          TournamentTeam(
            id: 't-a1',
            tournamentId: mixedTournament.id,
            name: 'Club Grupo A1',
            shortCode: 'GA1',
            groupName: 'Grupo A',
          ),
          TournamentTeam(
            id: 't-a2',
            tournamentId: mixedTournament.id,
            name: 'Club Grupo A2',
            shortCode: 'GA2',
            groupName: 'Grupo A',
          ),
          TournamentTeam(
            id: 't-b1',
            tournamentId: mixedTournament.id,
            name: 'Club Grupo B1',
            shortCode: 'GB1',
            groupName: 'Grupo B',
          ),
          TournamentTeam(
            id: 'cat-nuevo',
            tournamentId: 'other-9',
            name: 'Club Nuevo Internacional FC',
            shortCode: 'CNI',
          ),
        ]);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: _buildTestHost(
              tournament: mixedTournament,
              teamsRepo: teamsRepo,
              home: Scaffold(
                body: AddTeamsToCompetitionModal(tournament: mixedTournament),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final addBtn = find.byKey(
          const Key('add_teams_action_button_cat-nuevo'),
        );
        await tester.ensureVisible(addBtn);
        await tester.pumpAndSettle();
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final updated = await teamsRepo.loadTeamsForTournament(
          mixedTournament.id,
        );
        final added = updated.firstWhere(
          (t) => t.name == 'Club Nuevo Internacional FC',
        );
        expect(added.groupName, 'Grupo B');
      },
    );
  });
}
