import 'package:flutter/foundation.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Item representing a registered player within the team squad tab view.
@immutable
class TeamSquadPlayerItem {
  final RegisteredPlayer player;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final String tournamentId;
  final PlayerPerformanceProfile performanceProfile;

  const TeamSquadPlayerItem({
    required this.player,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.tournamentId,
    required this.performanceProfile,
  });

  bool get isEligible => player.isEligible;
  int get shirtNumber => player.shirtNumber;
  String get fullName => player.fullName;
  PlayerPosition get position => player.position;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamSquadPlayerItem &&
        other.player == player &&
        other.teamId == teamId &&
        other.teamName == teamName &&
        other.teamShortCode == teamShortCode &&
        other.tournamentId == tournamentId &&
        other.performanceProfile == performanceProfile;
  }

  @override
  int get hashCode => Object.hash(
    player,
    teamId,
    teamName,
    teamShortCode,
    tournamentId,
    performanceProfile,
  );
}

/// Immutable presentation model for the Team Squad ("Plantilla") tab view.
@immutable
class TeamSquadRoster {
  final String teamId;
  final TournamentTeam? team;
  final List<TeamSquadPlayerItem> goalkeepers;
  final List<TeamSquadPlayerItem> defenders;
  final List<TeamSquadPlayerItem> midfielders;
  final List<TeamSquadPlayerItem> forwards;
  final List<PlayerPerformanceProfile> allProfiles;

  const TeamSquadRoster({
    required this.teamId,
    required this.team,
    required this.goalkeepers,
    required this.defenders,
    required this.midfielders,
    required this.forwards,
    required this.allProfiles,
  });

  int get totalPlayers =>
      goalkeepers.length +
      defenders.length +
      midfielders.length +
      forwards.length;

  bool get hasPlayers => totalPlayers > 0;

  List<TeamSquadPlayerItem> playersForPosition(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return goalkeepers;
      case PlayerPosition.defender:
        return defenders;
      case PlayerPosition.midfielder:
        return midfielders;
      case PlayerPosition.forward:
        return forwards;
    }
  }

  /// Deterministically creates a [TeamSquadRoster] from the local teams catalog.
  factory TeamSquadRoster.fromCatalog({
    required String teamId,
    required List<TournamentTeam> teams,
    Map<String, PlayerPerformanceProfile> playerProfilesById = const {},
  }) {
    TournamentTeam? team;
    for (final t in teams) {
      if (t.id == teamId) {
        team = t;
        break;
      }
    }

    if (team == null || team.players.isEmpty) {
      return TeamSquadRoster(
        teamId: teamId,
        team: team,
        goalkeepers: const [],
        defenders: const [],
        midfielders: const [],
        forwards: const [],
        allProfiles: const [],
      );
    }

    final sortedPlayers = [...team.players]
      ..sort((a, b) {
        final cmpShirt = a.shirtNumber.compareTo(b.shirtNumber);
        if (cmpShirt != 0) return cmpShirt;
        final cmpName = a.fullName.toLowerCase().compareTo(
          b.fullName.toLowerCase(),
        );
        if (cmpName != 0) return cmpName;
        return a.id.compareTo(b.id);
      });

    final goalkeepers = <TeamSquadPlayerItem>[];
    final defenders = <TeamSquadPlayerItem>[];
    final midfielders = <TeamSquadPlayerItem>[];
    final forwards = <TeamSquadPlayerItem>[];
    final allProfiles = <PlayerPerformanceProfile>[];

    final effectiveTournamentId = team.tournamentId.trim().isNotEmpty
        ? team.tournamentId
        : 'tournament_${team.id}';

    for (final player in sortedPlayers) {
      final profile =
          playerProfilesById[player.id] ??
          PlayerPerformanceProfile(
            playerId: player.id,
            tournamentId: effectiveTournamentId,
            fullName: player.fullName,
            shirtNumber: player.shirtNumber,
            position: player.position,
            teamId: team.id,
            teamName: team.name,
            teamShortCode: team.shortCode,
            isSuspended: !player.isEligible,
          );

      allProfiles.add(profile);

      final item = TeamSquadPlayerItem(
        player: player,
        teamId: team.id,
        teamName: team.name,
        teamShortCode: team.shortCode,
        tournamentId: effectiveTournamentId,
        performanceProfile: profile,
      );

      switch (player.position) {
        case PlayerPosition.goalkeeper:
          goalkeepers.add(item);
        case PlayerPosition.defender:
          defenders.add(item);
        case PlayerPosition.midfielder:
          midfielders.add(item);
        case PlayerPosition.forward:
          forwards.add(item);
      }
    }

    return TeamSquadRoster(
      teamId: teamId,
      team: team,
      goalkeepers: List.unmodifiable(goalkeepers),
      defenders: List.unmodifiable(defenders),
      midfielders: List.unmodifiable(midfielders),
      forwards: List.unmodifiable(forwards),
      allProfiles: List.unmodifiable(allProfiles),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamSquadRoster &&
        other.teamId == teamId &&
        other.team == team &&
        listEquals(other.goalkeepers, goalkeepers) &&
        listEquals(other.defenders, defenders) &&
        listEquals(other.midfielders, midfielders) &&
        listEquals(other.forwards, forwards) &&
        listEquals(other.allProfiles, allProfiles);
  }

  @override
  int get hashCode => Object.hash(
    teamId,
    team,
    Object.hashAll(goalkeepers),
    Object.hashAll(defenders),
    Object.hashAll(midfielders),
    Object.hashAll(forwards),
    Object.hashAll(allProfiles),
  );
}
