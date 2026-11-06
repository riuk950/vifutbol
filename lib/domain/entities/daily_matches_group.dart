import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';

/// Enum para representar la selección en la barra de navegación rápida de fechas.
enum MatchesDailyTab { yesterday, today, tomorrow, customDate }

/// Agrupa una competición activa con los partidos del día correspondientes.
class TournamentMatchesGroup {
  const TournamentMatchesGroup({
    required this.tournament,
    required this.matches,
  });

  final ChampionshipTournament tournament;
  final List<ChampionshipMatch> matches;

  bool get hasLiveMatches =>
      matches.any((match) => match.status == MatchStatus.inProgress);
}
