import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Autonomous, self-contained and schema-versioned tournament backup package.
class TournamentBackupPackage {
  static const String currentSignature = 'vifutbol.tournament_backup';
  static const int currentSchemaVersion = 1;

  const TournamentBackupPackage({
    this.formatSignature = currentSignature,
    this.schemaVersion = currentSchemaVersion,
    required this.exportedAt,
    required this.tournament,
    this.teams = const [],
    this.matches = const [],
    this.matchReports = const [],
    this.newsItems = const [],
    this.honorRoll,
  });

  final String formatSignature;
  final int schemaVersion;
  final DateTime exportedAt;
  final ChampionshipTournament tournament;
  final List<TournamentTeam> teams;
  final List<ChampionshipMatch> matches;
  final List<DigitalMatchReport> matchReports;
  final List<TournamentNewsItem> newsItems;
  final SeasonHonorRoll? honorRoll;

  /// Suggested default file name for saving or exporting the package.
  String get suggestedFileName {
    final year = exportedAt.year.toString();
    final month = exportedAt.month.toString().padLeft(2, '0');
    final day = exportedAt.day.toString().padLeft(2, '0');
    return 'respaldo_${tournament.id}_$year$month$day.json';
  }

  /// Total count of enrolled players across all teams in this tournament.
  int get totalPlayersCount =>
      teams.fold<int>(0, (sum, t) => sum + t.players.length);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'formatSignature': formatSignature,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'tournament': tournament.toJson(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'matchReports': matchReports.map((r) => r.toJson()).toList(),
      'newsItems': newsItems.map((n) => n.toJson()).toList(),
      if (honorRoll != null) 'honorRoll': honorRoll!.toJson(),
    };
  }

  factory TournamentBackupPackage.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'] as List<dynamic>? ?? const [];
    final rawMatches = json['matches'] as List<dynamic>? ?? const [];
    final rawReports = json['matchReports'] as List<dynamic>? ?? const [];
    final rawNews = json['newsItems'] as List<dynamic>? ?? const [];
    final rawHonorRoll = json['honorRoll'] as Map<String, dynamic>?;

    return TournamentBackupPackage(
      formatSignature: json['formatSignature'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      tournament: ChampionshipTournament.fromJson(
        (json['tournament'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      teams: rawTeams
          .whereType<Map<String, dynamic>>()
          .map(TournamentTeam.fromJson)
          .toList(),
      matches: rawMatches
          .whereType<Map<String, dynamic>>()
          .map(ChampionshipMatch.fromJson)
          .toList(),
      matchReports: rawReports
          .whereType<Map<String, dynamic>>()
          .map(DigitalMatchReport.fromJson)
          .toList(),
      newsItems: rawNews
          .whereType<Map<String, dynamic>>()
          .map(TournamentNewsItem.fromJson)
          .toList(),
      honorRoll: rawHonorRoll != null
          ? SeasonHonorRoll.fromJson(rawHonorRoll)
          : null,
    );
  }
}
