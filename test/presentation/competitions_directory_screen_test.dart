import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/directories/competitions_directory_screen.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  bool get isUsingFallbackMemory => false;

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }
}

class FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class FakeTournamentsRepository implements TournamentsRepository {
  final List<ChampionshipTournament> tournaments;

  FakeTournamentsRepository(this.tournaments);

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async => tournaments;

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async => tournament;

  @override
  Future<void> deleteTournament(String tournamentId) async {}

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(dynamic draft) async {}

  @override
  Future<void> clearDraft() async {}
}

Widget createCompetitionsTestApp({
  required List<ChampionshipTournament> tournaments,
  UserRole role = UserRole.fan,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
      localStorageRepositoryProvider.overrideWithValue(
        FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        FakeConnectivityRepository(),
      ),
      activeUserRoleProvider.overrideWith((ref) => role),
      tournamentsControllerProvider.overrideWith((ref) {
        final controller = TournamentsController(
          tournamentsRepository: FakeTournamentsRepository(tournaments),
          manageTournamentsUseCase: ref.watch(manageTournamentsUseCaseProvider),
        );
        return controller;
      }),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: const CompetitionsDirectoryScreen(),
    ),
  );
}

void main() {
  final tournament1 = ChampionshipTournament(
    id: 't-1',
    name: 'Liga Premier Apertura',
    category: 'Libre Masculino',
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 6, 30),
    updatedAt: DateTime(2026, 3, 1),
  );

  final tournament2 = ChampionshipTournament(
    id: 't-2',
    name: 'Copa Élite Verano',
    category: 'Sub-20',
    format: TournamentFormat.knockoutCup,
    status: TournamentStatus.openRegistration,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 7, 1),
  );

  group('CompetitionsDirectoryScreen Widget Tests', () {
    testWidgets(
      'renders all competitions and allows real-time search with diacritics',
      (tester) async {
        await tester.pumpWidget(
          createCompetitionsTestApp(
            tournaments: [tournament1, tournament2],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        // Both tournaments displayed initially
        expect(find.byKey(const Key('competition_item_t-1')), findsOneWidget);
        expect(find.byKey(const Key('competition_item_t-2')), findsOneWidget);

        // Search with accent-free text 'elite' should match 'Copa Élite Verano'
        await tester.enterText(
          find.byKey(const Key('competitions_search_bar')),
          'elite',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('competition_item_t-1')), findsNothing);
        expect(find.byKey(const Key('competition_item_t-2')), findsOneWidget);

        // Clear button restores all items
        await tester.tap(find.byKey(const Key('search_bar_clear_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('competition_item_t-1')), findsOneWidget);
        expect(find.byKey(const Key('competition_item_t-2')), findsOneWidget);
      },
    );

    testWidgets('displays empty state when search yields no results', (
      tester,
    ) async {
      await tester.pumpWidget(
        createCompetitionsTestApp(
          tournaments: [tournament1, tournament2],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('competitions_search_bar')),
        'Torneo Inexistente',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competitions_empty_state')), findsOneWidget);
      expect(
        find.text('No se encontraron competiciones con ese criterio.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders create tournament button for organizer and hides for fan',
      (tester) async {
        // Fan role
        await tester.pumpWidget(
          createCompetitionsTestApp(
            tournaments: [tournament1],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('create_tournament_from_directory_button')),
          findsNothing,
        );

        // Organizer role
        await tester.pumpWidget(
          createCompetitionsTestApp(
            tournaments: [tournament1],
            role: UserRole.organizer,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('create_tournament_from_directory_button')),
          findsOneWidget,
        );
      },
    );
  });
}
