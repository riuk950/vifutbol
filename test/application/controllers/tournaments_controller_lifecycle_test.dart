import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
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

  final openTournament = ChampionshipTournament(
    id: 't-open',
    name: 'Torneo Abierto',
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
    when(
      () => mockRepo.loadTournaments(),
    ).thenAnswer((_) async => [openTournament, inProgressTournament]);
    when(() => mockRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => mockRepo.saveTournament(any())).thenAnswer(
      (inv) async => inv.positionalArguments[0] as ChampionshipTournament,
    );

    manageUseCase = ManageTournamentsUseCase(mockRepo);
    controller = TournamentsController(
      tournamentsRepository: mockRepo,
      manageTournamentsUseCase: manageUseCase,
    );
  });

  group('TournamentsController - Lifecycle Transitions (US3)', () {
    test('blocks transition to inProgress if enrolled teams < 2', () async {
      await controller.loadCatalog();

      final success = await controller.transitionTournamentStatus(
        tournament: openTournament,
        targetStatus: TournamentStatus.inProgress,
        actorRole: UserRole.organizer,
        enrolledTeamsCount: 1,
        hasGeneratedFixture: true,
      );

      expect(success, isFalse);
      expect(controller.state.lastFailure, isA<TournamentValidationFailure>());
      expect(
        (controller.state.lastFailure as TournamentValidationFailure).code,
        TournamentValidationErrorCode.insufficientTeamsToStart,
      );
    });

    test(
      'blocks transition to inProgress if fixture is not generated',
      () async {
        await controller.loadCatalog();

        final success = await controller.transitionTournamentStatus(
          tournament: openTournament,
          targetStatus: TournamentStatus.inProgress,
          actorRole: UserRole.organizer,
          enrolledTeamsCount: 4,
          hasGeneratedFixture: false,
        );

        expect(success, isFalse);
        expect(
          controller.state.lastFailure,
          isA<TournamentValidationFailure>(),
        );
        expect(
          (controller.state.lastFailure as TournamentValidationFailure).code,
          TournamentValidationErrorCode.missingFixtureToStart,
        );
      },
    );

    test(
      'allows transition to inProgress when teams >= 2 and fixture exists',
      () async {
        await controller.loadCatalog();

        final success = await controller.transitionTournamentStatus(
          tournament: openTournament,
          targetStatus: TournamentStatus.inProgress,
          actorRole: UserRole.organizer,
          enrolledTeamsCount: 4,
          hasGeneratedFixture: true,
        );

        expect(success, isTrue);
      },
    );

    test(
      'blocks backward transition from inProgress to openRegistration',
      () async {
        await controller.loadCatalog();

        final success = await controller.transitionTournamentStatus(
          tournament: inProgressTournament,
          targetStatus: TournamentStatus.openRegistration,
          actorRole: UserRole.organizer,
        );

        expect(success, isFalse);
        expect(
          (controller.state.lastFailure as TournamentValidationFailure).code,
          TournamentValidationErrorCode.invalidStatusTransition,
        );
      },
    );

    test('allows transition from inProgress to finished', () async {
      await controller.loadCatalog();

      final success = await controller.transitionTournamentStatus(
        tournament: inProgressTournament,
        targetStatus: TournamentStatus.finished,
        actorRole: UserRole.organizer,
      );

      expect(success, isTrue);
    });
  });
}
