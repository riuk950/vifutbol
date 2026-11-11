import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

class _FakeTeamsRepository implements TeamsRepository {
  final Map<String, TournamentTeam> teams = {};

  @override
  Future<List<TournamentTeam>> loadTeams() async => teams.values.toList();

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    return teams.values.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async {
    teams[team.id] = team;
    return team;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    teams.remove(teamId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChampionshipTournament _buildTournament({
  String id = 'tourn-target',
  TournamentStatus status = TournamentStatus.openRegistration,
  TournamentFormat format = TournamentFormat.league,
  int groupCount = 2,
  int maxPlayersPerTeam = 22,
}) {
  return ChampionshipTournament(
    id: id,
    name: 'Torneo Apertura',
    category: 'Libre',
    status: status,
    format: format,
    rules: TournamentRulesConfig(
      maxPlayersPerTeam: maxPlayersPerTeam,
      groupStageConfig: GroupStageConfig(groupCount: groupCount),
    ),
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 12, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

TournamentTeam _buildCatalogTeam({
  String id = 'source-team-1',
  String tournamentId = 'tourn-old',
  String name = 'Atlético del Sur',
  String shortCode = 'ADS',
  List<RegisteredPlayer> players = const [],
}) {
  return TournamentTeam(
    id: id,
    tournamentId: tournamentId,
    name: name,
    shortCode: shortCode,
    crestShape: TeamCrestShape.diamond,
    primaryColorHex: 0xFF1E88E5,
    secondaryColorHex: 0xFFFFFFFF,
    eligibilityStatus: TeamEligibilityStatus.eligible,
    players: players,
    coachId: 'coach-77',
    updatedAt: DateTime(2026, 5, 1),
  );
}

void main() {
  late _FakeTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;

  setUp(() {
    repository = _FakeTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);
  });

  group('ManageTeamsEligibilityUseCase.enrollExistingTeamFromCatalog', () {
    test('rejects non-organizer roles with UnauthorizedRoleFailure', () async {
      final tournament = _buildTournament();
      final source = _buildCatalogTeam();

      for (final role in [
        UserRole.coach,
        UserRole.referee,
        UserRole.player,
        UserRole.fan,
      ]) {
        expect(
          () => useCase.enrollExistingTeamFromCatalog(
            sourceTeam: source,
            tournament: tournament,
            actorRole: role,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      }
    });

    test('rejects finished tournaments', () async {
      final tournament = _buildTournament(status: TournamentStatus.finished);
      final source = _buildCatalogTeam();

      expect(
        () => useCase.enrollExistingTeamFromCatalog(
          sourceTeam: source,
          tournament: tournament,
          actorRole: UserRole.organizer,
        ),
        throwsA(isA<TeamEligibilityValidationFailure>()),
      );
    });

    test(
      'rejects duplicate team matching diacritic-insensitive normalized name',
      () async {
        final tournament = _buildTournament();
        await repository.saveTeam(
          TournamentTeam(
            id: 'existing-1',
            tournamentId: tournament.id,
            name: 'Aguilas FC',
            shortCode: 'AGU',
          ),
        );

        final source = _buildCatalogTeam(name: 'Águilas FC', shortCode: 'AGL');

        expect(
          () => useCase.enrollExistingTeamFromCatalog(
            sourceTeam: source,
            tournament: tournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TeamEligibilityValidationFailure>().having(
              (f) => f.code,
              'code',
              TeamEligibilityErrorCode.duplicateTeamNameInTournament,
            ),
          ),
        );
      },
    );

    test(
      'enrolls team with pendingVerification status and copies eligible players as pending',
      () async {
        final tournament = _buildTournament();
        final source = _buildCatalogTeam(
          players: const [
            RegisteredPlayer(
              id: 'p1',
              fullName: 'Carlos Ruiz',
              documentId: 'DOC-101',
              shirtNumber: 9,
              position: PlayerPosition.forward,
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'p2',
              fullName: 'Luis Diaz',
              documentId: 'DOC-102',
              shirtNumber: 10,
              position: PlayerPosition.midfielder,
              isEligible: true,
            ),
          ],
        );

        final result = await useCase.enrollExistingTeamFromCatalog(
          sourceTeam: source,
          tournament: tournament,
          actorRole: UserRole.organizer,
          generatedTeamId: 'enrolled-team-1',
        );

        expect(result.enrolledTeam.id, 'enrolled-team-1');
        expect(result.enrolledTeam.id, isNot(source.id));
        expect(result.enrolledTeam.tournamentId, tournament.id);
        expect(result.enrolledTeam.name, source.name);
        expect(result.enrolledTeam.shortCode, source.shortCode);
        expect(result.enrolledTeam.crestShape, source.crestShape);
        expect(result.enrolledTeam.primaryColorHex, source.primaryColorHex);
        expect(result.enrolledTeam.secondaryColorHex, source.secondaryColorHex);
        expect(result.enrolledTeam.coachId, source.coachId);
        expect(
          result.enrolledTeam.eligibilityStatus,
          TeamEligibilityStatus.pendingVerification,
        );
        expect(result.enrolledTeam.groupName, isNull);
        expect(result.copiedPlayersCount, 2);
        expect(result.skippedConflictingPlayersCount, 0);
        expect(result.enrolledTeam.players.every((p) => !p.isEligible), isTrue);

        final stored = await repository.loadTeamsForTournament(tournament.id);
        expect(stored.length, 1);
      },
    );

    test(
      'skips and counts players whose documentId already exists in another team of the same tournament',
      () async {
        final tournament = _buildTournament(maxPlayersPerTeam: 2);
        await repository.saveTeam(
          TournamentTeam(
            id: 'rival-1',
            tournamentId: tournament.id,
            name: 'Rival FC',
            shortCode: 'RIV',
            players: const [
              RegisteredPlayer(
                id: 'rp1',
                fullName: 'Jugador Ya Inscrito',
                documentId: 'doc-101',
                shirtNumber: 7,
                position: PlayerPosition.midfielder,
              ),
            ],
          ),
        );

        final source = _buildCatalogTeam(
          players: const [
            RegisteredPlayer(
              id: 'p1',
              fullName: 'Carlos Ruiz',
              documentId: 'DOC-101',
              shirtNumber: 9,
              position: PlayerPosition.forward,
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'p2',
              fullName: 'Luis Diaz',
              documentId: 'DOC-102',
              shirtNumber: 10,
              position: PlayerPosition.midfielder,
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'p3',
              fullName: 'Mateo Silva',
              documentId: 'DOC-103',
              shirtNumber: 11,
              position: PlayerPosition.defender,
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'p4',
              fullName: 'Extra Cap',
              documentId: 'DOC-104',
              shirtNumber: 12,
              position: PlayerPosition.goalkeeper,
              isEligible: true,
            ),
          ],
        );

        final result = await useCase.enrollExistingTeamFromCatalog(
          sourceTeam: source,
          tournament: tournament,
          actorRole: UserRole.organizer,
          generatedTeamId: 'enrolled-team-2',
        );

        expect(result.copiedPlayersCount, 2);
        expect(result.skippedConflictingPlayersCount, 2);
        expect(result.enrolledTeam.players.map((p) => p.documentId), [
          'DOC-102',
          'DOC-103',
        ]);
      },
    );

    test(
      'auto-assigns least-populated group for mixedGroupsAndKnockout format',
      () async {
        final tournament = _buildTournament(
          format: TournamentFormat.mixedGroupsAndKnockout,
          groupCount: 2,
        );
        await repository.saveTeam(
          TournamentTeam(
            id: 't-g-a-1',
            tournamentId: tournament.id,
            name: 'Equipo A1',
            shortCode: 'EA1',
            groupName: 'Grupo A',
          ),
        );
        await repository.saveTeam(
          TournamentTeam(
            id: 't-g-a-2',
            tournamentId: tournament.id,
            name: 'Equipo A2',
            shortCode: 'EA2',
            groupName: 'Grupo A',
          ),
        );
        await repository.saveTeam(
          TournamentTeam(
            id: 't-g-b-1',
            tournamentId: tournament.id,
            name: 'Equipo B1',
            shortCode: 'EB1',
            groupName: 'Grupo B',
          ),
        );

        final source = _buildCatalogTeam(name: 'Nuevo Mixto', shortCode: 'MIX');
        final result = await useCase.enrollExistingTeamFromCatalog(
          sourceTeam: source,
          tournament: tournament,
          actorRole: UserRole.organizer,
          generatedTeamId: 'enrolled-mixed-1',
        );

        expect(result.assignedGroupName, 'Grupo B');
        expect(result.enrolledTeam.groupName, 'Grupo B');
      },
    );
  });
}
