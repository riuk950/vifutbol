import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

class PublishTournamentNewsUseCase {
  const PublishTournamentNewsUseCase({
    required this.newsRepository,
    this.tournamentsRepository,
  });

  final TournamentNewsRepository newsRepository;
  final TournamentsRepository? tournamentsRepository;

  Future<TournamentNewsItem> execute({
    required TournamentNewsItem newsItem,
    required UserRole userRole,
    ChampionshipTournament? tournament,
  }) async {
    if (userRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los organizadores pueden publicar noticias o comunicados oficiales.',
      );
    }

    if (tournament != null && tournament.status == TournamentStatus.finished) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.tournamentAlreadyFinished,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
      );
    }

    if (tournamentsRepository != null) {
      final tournaments = await tournamentsRepository!.loadTournaments();
      final target = tournaments
          .where((t) => t.id == newsItem.tournamentId)
          .firstOrNull;
      if (target != null && target.status == TournamentStatus.finished) {
        throw const TournamentValidationFailure(
          TournamentValidationErrorCode.tournamentAlreadyFinished,
          'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
        );
      }
    }

    return newsRepository.saveNewsItem(newsItem);
  }
}

class DeleteTournamentNewsUseCase {
  const DeleteTournamentNewsUseCase({
    required this.newsRepository,
    this.tournamentsRepository,
  });

  final TournamentNewsRepository newsRepository;
  final TournamentsRepository? tournamentsRepository;

  Future<void> execute({
    required String newsItemId,
    required UserRole userRole,
    ChampionshipTournament? tournament,
  }) async {
    if (userRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los organizadores pueden eliminar noticias o comunicados oficiales.',
      );
    }

    if (tournament != null && tournament.status == TournamentStatus.finished) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.tournamentAlreadyFinished,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
      );
    }

    if (tournamentsRepository != null) {
      final tournaments = await tournamentsRepository!.loadTournaments();
      for (final t in tournaments) {
        if (t.status == TournamentStatus.finished) {
          final items = await newsRepository.loadNewsForTournament(t.id);
          if (items.any((n) => n.id == newsItemId)) {
            throw const TournamentValidationFailure(
              TournamentValidationErrorCode.tournamentAlreadyFinished,
              'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
            );
          }
        }
      }
    }

    return newsRepository.deleteNewsItem(newsItemId);
  }
}
