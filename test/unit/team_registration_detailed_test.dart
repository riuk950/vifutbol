import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

class _MockTeamsRepository extends Mock implements TeamsRepository {}

void main() {
  late _MockTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      TournamentTeam(id: 'fallback', name: 'Fallback', shortCode: 'FB'),
    );
  });

  setUp(() {
    repository = _MockTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);
  });

  group('HU 27.2 Entities roundtrip', () {
    test('TournamentTeam preserves delegateName and foundedDate in JSON', () {
      final team = TournamentTeam(
        id: 't-1',
        name: 'Atlético Andino',
        shortCode: 'AA',
        primaryColorHex: 0xFF00E676,
        secondaryColorHex: 0xFF0A0E17,
        delegateName: 'María Fernanda Gómez',
        foundedDate: DateTime(2018, 7, 15),
      );
      final roundtrip = TournamentTeam.fromJson(team.toJson());
      expect(roundtrip.delegateName, 'María Fernanda Gómez');
      expect(roundtrip.foundedDate, DateTime(2018, 7, 15));
    });

    test('TeamDirectoryItem preserves delegateName and foundedDate in JSON', () {
      final item = TeamDirectoryItem(
        id: 'td-1',
        name: 'Real Sabana',
        shortCode: 'RS',
        delegateName: 'Jorge Ramírez',
        foundedDate: DateTime(2020, 1, 10),
        updatedAt: DateTime(2026, 11, 26),
      );
      final roundtrip = TeamDirectoryItem.fromJson(item.toJson());
      expect(roundtrip, equals(item));
    });
  });

  group('ManageTeamsEligibilityUseCase HU 27.2 validations', () {
    test('rejects future foundedDate', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final team = TournamentTeam(
        id: 't-future',
        name: 'Futuro FC',
        shortCode: 'FFC',
        delegateName: 'Luis Pérez',
        foundedDate: tomorrow,
      );

      await expectLater(
        useCase.registerOrUpdateTeam(team: team, actorRole: UserRole.coach),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (e) => e.code,
            'code',
            TeamEligibilityErrorCode.invalidFoundedDate,
          ),
        ),
      );
    });

    test('rejects identical primary and secondary colors', () async {
      final team = TournamentTeam(
        id: 't-same-color',
        name: 'Monocromo FC',
        shortCode: 'MFC',
        primaryColorHex: 0xFF00E676,
        secondaryColorHex: 0xFF00E676,
        delegateName: 'Luis Pérez',
        foundedDate: DateTime(2020, 5, 1),
      );

      await expectLater(
        useCase.registerOrUpdateTeam(team: team, actorRole: UserRole.coach),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (e) => e.code,
            'code',
            TeamEligibilityErrorCode.duplicateTeamColors,
          ),
        ),
      );
    });

    test('rejects duplicate team name ignoring case, diacritics, and extra spaces', () async {
      when(() => repository.loadTeams()).thenAnswer(
        (_) async => [
          TournamentTeam(
            id: 'existing-1',
            name: 'Atlético Bogotá',
            shortCode: 'AB',
          ),
        ],
      );

      final duplicate = TournamentTeam(
        id: 'new-1',
        name: '  atletico   bogota  ',
        shortCode: 'ABG',
        delegateName: 'Ana Ruiz',
        foundedDate: DateTime(2021, 3, 12),
      );

      await expectLater(
        useCase.registerOrUpdateTeam(
          team: duplicate,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (e) => e.code,
            'code',
            TeamEligibilityErrorCode.duplicateTeamNameInTournament,
          ),
        ),
      );
    });

    test('rejects unauthorized roles (fan/player/referee)', () async {
      final team = TournamentTeam(
        id: 't-unauth',
        name: 'No Permitido FC',
        shortCode: 'NPF',
        delegateName: 'Pedro',
        foundedDate: DateTime(2020, 1, 1),
      );

      for (final role in [UserRole.fan, UserRole.player, UserRole.referee]) {
        await expectLater(
          useCase.registerOrUpdateTeam(team: team, actorRole: role),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      }
    });

    test('saves autonomous team trimming delegateName and preserving foundedDate and colors', () async {
      when(() => repository.loadTeams()).thenAnswer((_) async => []);
      when(() => repository.saveTeam(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as TournamentTeam,
      );

      final team = TournamentTeam(
        id: 't-ok',
        name: 'Estrella del Sur',
        shortCode: 'es',
        primaryColorHex: 0xFF2979FF,
        secondaryColorHex: 0xFFFFD600,
        delegateName: '  Carlos Vives  ',
        foundedDate: DateTime(2019, 8, 20),
      );

      final saved = await useCase.registerOrUpdateTeam(
        team: team,
        actorRole: UserRole.coach,
      );

      expect(saved.shortCode, 'ES');
      expect(saved.delegateName, 'Carlos Vives');
      expect(saved.foundedDate, DateTime(2019, 8, 20));
      expect(saved.primaryColorHex, 0xFF2979FF);
      expect(saved.secondaryColorHex, 0xFFFFD600);
    });
  });
}
