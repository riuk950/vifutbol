import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';

class MockTournamentsRepository extends Mock implements TournamentsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ChampionshipTournament(
        id: 'dummy',
        name: 'Dummy',
        category: 'Dummy',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  late MockTournamentsRepository mockRepo;
  late ManageTournamentsUseCase manageUseCase;
  late TournamentsController controller;
  final inMemoryTournaments = <ChampionshipTournament>[];

  final organizerUser = UserAccount(
    id: 'org-test-user',
    fullName: 'Organizador Oficial',
    email: 'organizador@vifutbol.com',
    activeRole: UserRole.organizer,
    authorizedRoles: {UserRole.organizer, UserRole.fan},
    onboardingCompleted: true,
  );

  final authState = AuthFlowState(
    session: AuthSession(
      sessionId: 'session-123',
      user: organizerUser,
      sessionToken: 'token-123',
      authenticatedAt: DateTime(2026, 5, 1),
    ),
  );

  setUp(() {
    mockRepo = MockTournamentsRepository();
    inMemoryTournaments.clear();

    when(
      () => mockRepo.loadTournaments(),
    ).thenAnswer((_) async => List.from(inMemoryTournaments));
    when(() => mockRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => mockRepo.clearDraft()).thenAnswer((_) async {});
    when(() => mockRepo.saveTournament(any())).thenAnswer((inv) async {
      final t = inv.positionalArguments[0] as ChampionshipTournament;
      final idx = inMemoryTournaments.indexWhere((x) => x.id == t.id);
      if (idx >= 0) {
        inMemoryTournaments[idx] = t;
      } else {
        inMemoryTournaments.insert(0, t);
      }
      return t;
    });
    when(() => mockRepo.deleteTournament(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments[0] as String;
      inMemoryTournaments.removeWhere((x) => x.id == id);
    });

    manageUseCase = ManageTournamentsUseCase(mockRepo);
    controller = TournamentsController(
      tournamentsRepository: mockRepo,
      manageTournamentsUseCase: manageUseCase,
    );
  });

  Widget buildTestableOrganizerPanel() {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(
          EnvironmentConfig.development(),
        ),
        localStorageRepositoryProvider.overrideWithValue(
          _FakeLocalStorageRepository(),
        ),
        tournamentsRepositoryProvider.overrideWithValue(mockRepo),
        tournamentsControllerProvider.overrideWith((ref) => controller),
        activeUserRoleProvider.overrideWithValue(UserRole.organizer),
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(authState),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('es'),
        home: Scaffold(
          body: SingleChildScrollView(child: OrganizerPanelContent()),
        ),
      ),
    );
  }

  group('Verification: Competitions Addition & Display in Organizer Panel', () {
    testWidgets(
      'shows empty state initially, then immediately adds and displays newly created tournament in panel',
      (tester) async {
        await controller.loadCatalog();

        await tester.pumpWidget(buildTestableOrganizerPanel());
        await tester.pumpAndSettle();

        // 1. Initial Empty State in the section
        expect(
          find.byKey(const Key('organizer_competitions_section')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_competitions_empty_state')),
          findsOneWidget,
        );
        expect(find.text('No tienes competiciones activas'), findsOneWidget);

        // 2. Add a new competition dynamically
        final newTournament = ChampionshipTournament(
          id: 'tournament-super-cup',
          name: 'Super Copa Intermunicipal 2026',
          category: 'Libre Masculino',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 9, 30),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.openRegistration,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 6, 1),
          organizerId: 'org-test-user',
        );

        await controller.saveTournament(
          tournament: newTournament,
          actorRole: UserRole.organizer,
        );

        // Pump to reflect reactive state in UI
        await tester.pumpAndSettle();

        // 3. Verify Empty State disappears and tournament card appears in Organizer Panel
        expect(
          find.byKey(const Key('organizer_competitions_empty_state')),
          findsNothing,
        );
        expect(
          find.byKey(
            const Key('organizer_competition_card_tournament-super-cup'),
          ),
          findsOneWidget,
        );
        expect(find.text('Super Copa Intermunicipal 2026'), findsOneWidget);
        expect(find.text('Libre Masculino'), findsOneWidget);

        // 4. Verify Status Badge shows "Inscripciones Abiertas"
        expect(
          find.byKey(
            const Key(
              'organizer_competition_status_badge_tournament-super-cup',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Inscripciones Abiertas'), findsOneWidget);

        // 5. Add a second tournament
        final secondTournament = ChampionshipTournament(
          id: 'tournament-liga-juvenil',
          name: 'Liga Juvenil Sub-18',
          category: 'Juvenil',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 11, 30),
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 7, 1),
          organizerId: 'org-test-user',
        );

        await controller.saveTournament(
          tournament: secondTournament,
          actorRole: UserRole.organizer,
        );

        await tester.pumpAndSettle();

        // Both cards are now listed in OrganizerPanelContent
        expect(
          find.byKey(
            const Key('organizer_competition_card_tournament-super-cup'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('organizer_competition_card_tournament-liga-juvenil'),
          ),
          findsOneWidget,
        );
        expect(find.text('Liga Juvenil Sub-18'), findsOneWidget);
      },
    );

    testWidgets('filters out competitions belonging to other organizers', (
      tester,
    ) async {
      await controller.loadCatalog();

      await tester.pumpWidget(buildTestableOrganizerPanel());
      await tester.pumpAndSettle();

      // Add a tournament belonging to someone else
      final otherOrganizerTournament = ChampionshipTournament(
        id: 'tournament-other-user',
        name: 'Torneo Privado Otro Organizador',
        category: 'Veteranos',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 31),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 8, 1),
        organizerId: 'some-other-organizer-id',
      );

      await controller.saveTournament(
        tournament: otherOrganizerTournament,
        actorRole: UserRole.organizer,
      );

      await tester.pumpAndSettle();

      // Should still be empty for the logged-in organizer
      expect(
        find.byKey(const Key('organizer_competitions_empty_state')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('organizer_competition_card_tournament-other-user'),
        ),
        findsNothing,
      );
      expect(find.text('Torneo Privado Otro Organizador'), findsNothing);
    });

    testWidgets(
      'renders competitions on 320x640 viewport with 1.3 text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        inMemoryTournaments.add(
          ChampionshipTournament(
            id: 'tournament-compact-check',
            name: 'Copa Extrema De Futbol Sala Metropolitano 2026',
            category: 'Primera Categoria Libre Superior',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2026, 12, 1),
            format: TournamentFormat.mixedGroupsAndKnockout,
            status: TournamentStatus.openRegistration,
            rules: const TournamentRulesConfig(),
            updatedAt: DateTime(2026, 9, 1),
            organizerId: 'org-test-user',
          ),
        );

        await controller.loadCatalog();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
              size: Size(320, 640),
            ),
            child: buildTestableOrganizerPanel(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('organizer_competition_card_tournament-compact-check'),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Copa Extrema De Futbol Sala Metropolitano 2026'),
          findsOneWidget,
        );
        // No overflow exceptions occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}
