import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Helper to generate players for testing roster quotas.
List<RegisteredPlayer> createTestPlayers(int count) {
  return List.generate(
    count,
    (index) => RegisteredPlayer(
      id: 'player-${index + 1}',
      fullName: 'Futbolista ${index + 1}',
      shirtNumber: index + 1,
      documentId: 'DOC-${1000 + index}',
      position: PlayerPosition.midfielder,
      isEligible: false,
    ),
  );
}

/// Helper to generate test teams with specific player counts and statuses.
TournamentTeam createTestTeam({
  String id = 'team-1',
  String tournamentId = 'tourn-1',
  String name = 'Club Deportivo Test',
  String shortCode = 'CDT',
  int playerCount = 11,
  TeamEligibilityStatus status = TeamEligibilityStatus.pendingVerification,
}) {
  return TournamentTeam(
    id: id,
    tournamentId: tournamentId,
    name: name,
    shortCode: shortCode,
    coachId: 'coach-seed-1',
    eligibilityStatus: status,
    players: createTestPlayers(playerCount),
  );
}

/// Helper to generate test tournaments.
ChampionshipTournament createTestTournament({
  String id = 'tourn-1',
  String name = 'Torneo Oficial Test',
  TournamentStatus status = TournamentStatus.openRegistration,
  int minPlayers = 11,
  int maxPlayers = 25,
}) {
  final now = DateTime.now();
  return ChampionshipTournament(
    id: id,
    name: name,
    category: 'Libre',
    format: TournamentFormat.league,
    status: status,
    startDate: now,
    endDate: now.add(const Duration(days: 90)),
    updatedAt: now,
    rules: TournamentRulesConfig(
      minPlayersPerTeam: minPlayers,
      maxPlayersPerTeam: maxPlayers,
      pointsForWin: 3,
      pointsForDraw: 1,
      pointsForLoss: 0,
    ),
  );
}
