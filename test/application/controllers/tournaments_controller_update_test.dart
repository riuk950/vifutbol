import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
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

  final initialTournaments = [
    ChampionshipTournament(
      id: 'tourn-1',
      name: 'Torneo Inicial',
      category: 'Libre',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 8, 30),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(),
      updatedAt: DateTime(2026, 5, 1),
      organizerId: 'org-test',
    ),
  ];

  setUp(() {
    mockRepo = MockTournamentsRepository();
    when(
      () => mockRepo.loadTournaments(),
    ).thenAnswer((_) async => initialTournaments);
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

  group('TournamentsController - updateTournamentMetadata (US2)', () {
    test('successfully updates metadata of existing tournament', () async {
      await controller.loadCatalog();

      final success = await controller.updateTournamentMetadata(
        tournamentId: 'tourn-1',
        name: 'Torneo Modificado 2026',
        category: 'Senior',
        format: TournamentFormat.knockoutCup,
        rules: const TournamentRulesConfig(pointsForWin: 4),
        actorRole: UserRole.organizer,
      );

      expect(success, isTrue);
      verify(
        () => mockRepo.saveTournament(
          any(
            that: predicate<ChampionshipTournament>((t) {
              return t.id == 'tourn-1' &&
                  t.name == 'Torneo Modificado 2026' &&
                  t.category == 'Senior' &&
                  t.format == TournamentFormat.knockoutCup &&
                  t.rules.pointsForWin == 4;
            }),
          ),
        ),
      ).called(1);
    });

    test('fails update if tournament is not found', () async {
      await controller.loadCatalog();

      final success = await controller.updateTournamentMetadata(
        tournamentId: 'non-existent',
        name: 'Nuevo Nombre',
        category: 'Libre',
        format: TournamentFormat.league,
        rules: const TournamentRulesConfig(),
        actorRole: UserRole.organizer,
      );

      expect(success, isFalse);
    });
  });
}
