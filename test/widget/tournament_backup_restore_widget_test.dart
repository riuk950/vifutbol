import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_backup_sheet.dart';

class _MockStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async =>
      _data[key] = value;

  Future<void> remove(String key) async => _data.remove(key);

  Future<void> clearAll() async => _data.clear();

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => false;
}

class _FakeTournamentsRepo implements TournamentsRepository {
  final Map<String, ChampionshipTournament> tournaments = {};

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async =>
      tournaments.values.toList();

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async {
    tournaments[tournament.id] = tournament;
    return tournament;
  }

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(TournamentDraft draft) async {}

  @override
  Future<void> clearDraft() async {}
}

void main() {
  final config = EnvironmentConfig.development();
  late _MockStorage storage;
  late _FakeTournamentsRepo tournamentsRepo;

  final sampleTournament = ChampionshipTournament(
    id: 't-test-1',
    name: 'Copa Apertura 2026',
    category: 'Libre',
    startDate: DateTime(2026, 4, 1),
    endDate: DateTime(2026, 6, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    updatedAt: DateTime(2026, 4, 1),
  );

  setUp(() async {
    storage = _MockStorage();
    tournamentsRepo = _FakeTournamentsRepo();
    await tournamentsRepo.saveTournament(sampleTournament);

    final teamsRepo = LocalTeamsRepository(storage: storage, config: config);
    await teamsRepo.saveTeam(
      TournamentTeam(
        id: 'team-1',
        tournamentId: 't-test-1',
        name: 'Halcones',
        shortCode: 'HAL',
      ),
    );
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
        localStorageRepositoryProvider.overrideWithValue(storage),
        environmentConfigProvider.overrideWithValue(config),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () => TournamentBackupSheet.show(
                  context: context,
                  tournament: sampleTournament,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders backup export summary and switches to import with validation error on corrupt JSON',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Verify export summary
      expect(find.text('Respaldo del Campeonato'), findsOneWidget);
      expect(find.text('Copa Apertura 2026'), findsOneWidget);
      expect(find.text('1 equipos inscritos'), findsOneWidget);
      expect(find.byKey(const Key('copy_backup_json_button')), findsOneWidget);

      // Switch to import tab
      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('backup_import_text_field')), findsOneWidget);
      expect(find.byKey(const Key('validate_backup_button')), findsOneWidget);

      // Enter corrupt text and validate
      await tester.enterText(
        find.byKey(const Key('backup_import_text_field')),
        '{invalid_json}',
      );
      await tester.tap(find.byKey(const Key('validate_backup_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.',
        ),
        findsOneWidget,
      );

      // Now enter valid package JSON
      final validPackageJson = jsonEncode({
        'formatSignature': 'vifutbol.tournament_backup',
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tournament': sampleTournament
            .copyWith(name: 'Copa Apertura Restaurada')
            .toJson(),
        'teams': [
          TournamentTeam(
            id: 'team-restored',
            tournamentId: 't-test-1',
            name: 'Águilas Doradas',
            shortCode: 'AGU',
          ).toJson(),
        ],
        'matches': [],
        'matchReports': [],
        'newsItems': [],
      });

      await tester.enterText(
        find.byKey(const Key('backup_import_text_field')),
        validPackageJson,
      );
      await tester.tap(find.byKey(const Key('validate_backup_button')));
      await tester.pumpAndSettle();

      // Verification checkbox should now be visible and restore button disabled
      final checkboxFinder = find.byKey(const Key('backup_two_step_checkbox'));
      await tester.ensureVisible(checkboxFinder);
      expect(checkboxFinder, findsOneWidget);

      final restoreButtonFinder = find.byKey(
        const Key('restore_backup_confirmed_button'),
      );
      await tester.ensureVisible(restoreButtonFinder);
      expect(restoreButtonFinder, findsOneWidget);

      // Tap checkbox to confirm
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Tap restore button
      await tester.tap(restoreButtonFinder);
      await tester.pumpAndSettle();

      // Verify modal dismissed and success snackbar shown
      expect(
        find.text('El campeonato fue restaurado con éxito desde el respaldo.'),
        findsOneWidget,
      );
      expect(
        tournamentsRepo.tournaments['t-test-1']?.name,
        equals('Copa Apertura Restaurada'),
      );
    },
  );
}
