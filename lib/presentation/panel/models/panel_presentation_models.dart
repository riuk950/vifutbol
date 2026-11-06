import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Presentation data aggregate for [OrganizerPanelContent].
class OrganizerPanelData {
  final int activeTournamentsCount;
  final int pendingScheduleMatchesCount;
  final int unseededTournamentsCount;

  const OrganizerPanelData({
    required this.activeTournamentsCount,
    required this.pendingScheduleMatchesCount,
    required this.unseededTournamentsCount,
  });
}

/// Presentation data aggregate for [CoachPanelContent].
class CoachPanelData {
  final TournamentTeam? team;
  final int totalPlayers;
  final int eligiblePlayersCount;
  final int suspendedPlayersCount;
  final ChampionshipMatch? nextMatch;

  const CoachPanelData({
    this.team,
    required this.totalPlayers,
    required this.eligiblePlayersCount,
    required this.suspendedPlayersCount,
    this.nextMatch,
  });
}

/// Presentation data aggregate for [RefereePanelContent].
class RefereePanelData {
  final List<ChampionshipMatch> assignedMatches;

  const RefereePanelData({required this.assignedMatches});
}

/// Presentation data aggregate for [PlayerPanelContent].
class PlayerPanelData {
  final RegisteredPlayer? player;
  final TournamentTeam? team;
  final bool isEligible;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int matchesPlayed;
  final ChampionshipMatch? nextMatch;

  const PlayerPanelData({
    this.player,
    this.team,
    required this.isEligible,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.matchesPlayed,
    this.nextMatch,
  });
}
