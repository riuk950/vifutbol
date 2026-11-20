import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/entities/venues_catalog_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_info_tab_view.dart';

class FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
    bool isLoading = false,
  }) : super(
         TournamentsCatalogState(
           viewState: isLoading
               ? const UiLoadingState<List<ChampionshipTournament>>()
               : UiSuccessState<List<ChampionshipTournament>>(tournaments),
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVenuesController extends StateNotifier<VenuesCatalogState>
    implements VenuesController {
  FakeVenuesController({List<SportsVenue> venues = const []})
    : super(
        VenuesCatalogState(
          viewState: UiSuccessState<List<SportsVenue>>(venues),
          venues: venues,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createInfoTabTestApp({
  required String tournamentId,
  List<ChampionshipTournament> tournaments = const [],
  bool isLoading = false,
  UserRole role = UserRole.fan,
  List<ChampionshipMatch> matches = const [],
  List<SportsVenue> venues = const [],
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(
          tournaments: tournaments,
          isLoading: isLoading,
        ),
      ),
      activeUserRoleProvider.overrideWithValue(role),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: matches),
      ),
      venuesControllerProvider.overrideWith(
        (ref) => FakeVenuesController(venues: venues),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: CompetitionInfoTabView(tournamentId: tournamentId)),
    ),
  );
}

void main() {
  group('CompetitionInfoTabView', () {
    const tournamentId = 'tourn-123';

    final testVenue = SportsVenue(
      id: 'venue-main',
      name: 'Complejo Deportivo Central',
      address: 'Av. Del Deporte 456, Lima',
      urbanReference: 'Frente al parque zonal',
      coordinate: const GeoCoordinate(
        latitude: -12.046374,
        longitude: -77.042793,
      ),
      pitches: const [
        VenuePitch(
          id: 'pitch-1',
          name: 'Cancha 1 (Principal)',
          surfaceType: PitchSurfaceType.naturalGrass,
          format: PitchFormat.football11,
          capacity: 1000,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        ),
        VenuePitch(
          id: 'pitch-2',
          name: 'Cancha 2 (Sintética)',
          surfaceType: PitchSurfaceType.syntheticGrass,
          format: PitchFormat.football7,
          capacity: 500,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        ),
      ],
      status: VenueOperationalStatus.active,
      updatedAt: DateTime(2026, 1, 1),
    );

    final testTournamentWithAudit = ChampionshipTournament(
      id: tournamentId,
      name: 'Liga de Honor 2026',
      category: 'Primera División',
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 11, 20),
      rules: const TournamentRulesConfig(
        pointsForWin: 3,
        pointsForDraw: 1,
        pointsForLoss: 0,
        halfDurationMinutes: 45,
        minPlayersPerTeam: 7,
        maxPlayersPerTeam: 25,
        yellowCardSuspensionLimit: 3,
        tiebreakerOrder: [
          TiebreakerCriterion.goalDifference,
          TiebreakerCriterion.goalsFor,
          TiebreakerCriterion.headToHead,
          TiebreakerCriterion.fairPlay,
        ],
      ),
      auditTrail: [
        RuleAuditEntry(
          recordedAt: DateTime(2026, 3, 5),
          summary: 'Ajuste de cupo de plantilla a 25 jugadores',
          reason: 'Aprobación unánime de delegados',
        ),
      ],
      updatedAt: DateTime(2026, 3, 5),
    );

    final testTournamentWithoutAudit = testTournamentWithAudit.copyWith(
      auditTrail: const [],
    );

    testWidgets(
      'renders scoring system, match duration, squad limits and disciplinary policy in read-only mode (US1)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        // Rules summary card is present
        expect(
          find.byKey(const Key('competition_tournament_rules_card')),
          findsOneWidget,
        );

        // Scoring system
        expect(find.text('Sistema de Puntuación'), findsOneWidget);
        expect(find.text('Victoria'), findsOneWidget);
        expect(find.text('Empate'), findsOneWidget);
        expect(find.text('Derrota'), findsOneWidget);
        expect(find.text('3 pts'), findsOneWidget);
        expect(find.text('1 pts'), findsOneWidget);
        expect(find.text('0 pts'), findsOneWidget);

        // Match parameters
        expect(find.text('Duración por tiempo reglamentario'), findsOneWidget);
        expect(find.text('45 min por tiempo'), findsOneWidget);

        // Squad limits
        expect(find.text('Cupo de jugadores por equipo'), findsOneWidget);
        expect(find.text('Mín. 7 / Máx. 25 jugadores'), findsOneWidget);

        // Disciplinary rules
        expect(
          find.text('Suspensión por acumulación de amarillas'),
          findsOneWidget,
        );
        expect(find.text('3 tarjetas amarillas'), findsOneWidget);

        // Read-only verification: no action buttons
        expect(
          find.byKey(const Key('edit_tournament_rules_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('start_tournament_status_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('finish_tournament_status_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('tournament_backup_action_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders tiebreaker criteria in ordered sequence and tournament dates (US2)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        // Tiebreaker criteria header
        expect(find.text('Criterios de Desempate en Tabla'), findsOneWidget);

        // Check sequential criteria texts
        expect(find.text('1'), findsOneWidget);
        expect(find.text('Diferencia de Gol'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Goles a Favor'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Duelo Directo'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(
          find.text('Fair Play (Menor puntaje de tarjetas)'),
          findsOneWidget,
        );

        // Official dates
        expect(find.text('01/03/2026 — 20/11/2026'), findsOneWidget);
        expect(find.text('Liga de Honor 2026'), findsOneWidget);
        expect(find.text('En Curso'), findsOneWidget);
      },
    );

    testWidgets(
      'displays audit trail for organizer when auditTrail is not empty (US3)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            role: UserRole.organizer,
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        // Organizer sees audit trail card
        expect(
          find.byKey(const Key('tournament_audit_trail_card')),
          findsOneWidget,
        );
        expect(
          find.text('Historial de Auditoría y Recálculos'),
          findsOneWidget,
        );
        expect(
          find.text('Ajuste de cupo de plantilla a 25 jugadores'),
          findsOneWidget,
        );
        expect(find.text('Aprobación unánime de delegados'), findsOneWidget);
      },
    );

    testWidgets('hides audit trail completely for non-organizer roles (US3)', (
      tester,
    ) async {
      for (final role in [
        UserRole.fan,
        UserRole.player,
        UserRole.coach,
        UserRole.referee,
      ]) {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            role: role,
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        // Non-organizer must NOT see the audit trail card
        expect(
          find.byKey(const Key('tournament_audit_trail_card')),
          findsNothing,
          reason: 'Audit trail must be hidden for role: $role',
        );
        expect(find.text('Historial de Auditoría y Recálculos'), findsNothing);
      }
    });

    testWidgets(
      'hides audit trail for organizer when auditTrail is empty (US3)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithoutAudit],
            role: UserRole.organizer,
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        // Empty audit trail must not render
        expect(
          find.byKey(const Key('tournament_audit_trail_card')),
          findsNothing,
        );
        expect(find.text('Historial de Auditoría y Recálculos'), findsNothing);
      },
    );

    testWidgets(
      'renders primary venue card with name, address, and pitches badge (US4)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            venues: [testVenue],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_main_venue_card')),
          findsOneWidget,
        );
        expect(find.text('Sede Principal'), findsOneWidget);
        expect(find.text('Complejo Deportivo Central'), findsOneWidget);
        expect(find.text('Av. Del Deporte 456, Lima'), findsOneWidget);
        expect(find.text('2 canchas disponibles'), findsOneWidget);
      },
    );

    testWidgets(
      'omits venue card gracefully when no venues are registered (US4)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: tournamentId,
            tournaments: [testTournamentWithAudit],
            venues: const [],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_main_venue_card')),
          findsNothing,
        );
        expect(find.text('Sede Principal'), findsNothing);
      },
    );

    testWidgets(
      'renders loading state when tournaments catalog is loading (US4)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(tournamentId: tournamentId, isLoading: true),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('competition_detail_info_loading')),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders not found state when tournament ID is not in catalog (US4)',
      (tester) async {
        await tester.pumpWidget(
          createInfoTabTestApp(
            tournamentId: 'non-existent-id',
            tournaments: [testTournamentWithAudit],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_info_not_found')),
          findsOneWidget,
        );
        expect(find.text('Competición No Encontrada'), findsOneWidget);
        expect(
          find.text(
            'No se pudo cargar la información reglamentaria del campeonato solicitado.',
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'renders without RenderFlex overflow at 320x640 with 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createInfoTabTestApp(
              tournamentId: tournamentId,
              tournaments: [testTournamentWithAudit],
              role: UserRole.organizer,
              venues: [testVenue],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('competition_detail_info_content')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_tournament_rules_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_main_venue_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HU 22.3: resolves primary venue from tournament.venueIds first and supports pull-to-refresh',
      (tester) async {
        final linkedVenue = SportsVenue(
          id: 'venue-linked',
          name: 'Estadio Linked',
          address: 'Calle 100 #10-20',
          urbanReference: 'Norte',
          coordinate: const GeoCoordinate(latitude: 4.7, longitude: -74.0),
          pitches: const [
            VenuePitch(
              id: 'p-1',
              name: 'Cancha 1',
              surfaceType: PitchSurfaceType.naturalGrass,
              format: PitchFormat.football11,
              capacity: 22,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: DateTime(2026, 2, 1),
        );
        final otherVenue = SportsVenue(
          id: 'venue-other',
          name: 'Estadio Other',
          address: 'Calle 50 #5-10',
          urbanReference: 'Centro',
          coordinate: const GeoCoordinate(latitude: 4.6, longitude: -74.1),
          pitches: const [
            VenuePitch(
              id: 'p-2',
              name: 'Cancha 2',
              surfaceType: PitchSurfaceType.naturalGrass,
              format: PitchFormat.football7,
              capacity: 14,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: DateTime(2026, 2, 1),
        );
        final tournamentWithVenueIds = testTournamentWithAudit.copyWith(
          venueIds: const ['venue-linked'],
        );

        var refreshCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentsControllerProvider.overrideWith(
                (ref) => FakeTournamentsController(
                  tournaments: [tournamentWithVenueIds],
                ),
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.fan),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => FakeMatchesCatalogController(),
              ),
              venuesControllerProvider.overrideWith(
                (ref) =>
                    FakeVenuesController(venues: [otherVenue, linkedVenue]),
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: Scaffold(
                body: CompetitionInfoTabView(
                  tournamentId: tournamentId,
                  onRefresh: () async {
                    refreshCount++;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Estadio Linked'), findsOneWidget);
        expect(find.text('Estadio Other'), findsNothing);

        await tester.fling(
          find.byKey(const Key('competition_detail_info_content')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();
        expect(refreshCount, 1);
      },
    );
  });
}
