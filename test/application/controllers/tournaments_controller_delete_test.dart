import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

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

  final openTournament1 = ChampionshipTournament(
    id: 't-open-1',
    name: 'Torneo Elegible',
    category: 'Libre',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 8, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 5, 1),
    organizerId: 'org-test',
  );

  final openTournament2 = ChampionshipTournament(
    id: 't-open-2',
    name: 'Torneo Segundo',
    category: 'Libre',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 8, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 5, 1),
    organizerId: 'org-test',
  );

  final inProgressTournament = ChampionshipTournament(
    id: 't-progress',
    name: 'Torneo En Curso',
    category: 'Libre',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 8, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 5, 1),
    organizerId: 'org-test',
  );

  setUp(() {
    mockRepo = MockTournamentsRepository();
    when(() => mockRepo.loadTournaments()).thenAnswer(
      (_) async => [openTournament1, openTournament2, inProgressTournament],
    );
    when(() => mockRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => mockRepo.deleteTournament(any())).thenAnswer((_) async {});

    manageUseCase = ManageTournamentsUseCase(mockRepo);
    controller = TournamentsController(
      tournamentsRepository: mockRepo,
      manageTournamentsUseCase: manageUseCase,
    );
  });

  group('TournamentsController - deleteTournament (US4)', () {
    test('blocks deletion if tournament is inProgress', () async {
      await controller.loadCatalog();

      final success = await controller.deleteTournament(
        tournamentId: 't-progress',
        hasStartedOrCompletedMatches: false,
      );

      expect(success, isFalse);
      expect(controller.state.lastFailure, isA<TournamentValidationFailure>());
      expect(
        (controller.state.lastFailure as TournamentValidationFailure).code,
        TournamentValidationErrorCode.tournamentCannotBeDeleted,
      );
      verifyNever(() => mockRepo.deleteTournament(any()));
    });

    test(
      'blocks deletion if tournament has started or completed matches',
      () async {
        await controller.loadCatalog();

        final success = await controller.deleteTournament(
          tournamentId: 't-open-1',
          hasStartedOrCompletedMatches: true,
        );

        expect(success, isFalse);
        expect(
          controller.state.lastFailure,
          isA<TournamentValidationFailure>(),
        );
        expect(
          (controller.state.lastFailure as TournamentValidationFailure).code,
          TournamentValidationErrorCode.tournamentCannotBeDeleted,
        );
        verifyNever(() => mockRepo.deleteTournament(any()));
      },
    );

    test(
      'successfully deletes eligible tournament, executes cascade, and resets selected tournament',
      () async {
        await controller.loadCatalog();
        controller.selectTournament('t-open-1');
        expect(controller.state.selectedTournamentId, 't-open-1');

        var cascadeExecuted = false;
        when(
          () => mockRepo.loadTournaments(),
        ).thenAnswer((_) async => [openTournament2, inProgressTournament]);

        final success = await controller.deleteTournament(
          tournamentId: 't-open-1',
          hasStartedOrCompletedMatches: false,
          onCascadeDeleteMatches: () async {
            cascadeExecuted = true;
          },
        );

        expect(success, isTrue);
        expect(cascadeExecuted, isTrue);
        verify(() => mockRepo.deleteTournament('t-open-1')).called(1);

        // Selected tournament falls back to first remaining tournament
        expect(controller.state.selectedTournamentId, 't-open-2');
      },
    );
  });
}
