import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';

class PublishTournamentNewsUseCase {
  const PublishTournamentNewsUseCase({required this.newsRepository});

  final TournamentNewsRepository newsRepository;

  Future<TournamentNewsItem> execute({
    required TournamentNewsItem newsItem,
    required UserRole userRole,
  }) async {
    if (userRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los organizadores pueden publicar noticias o comunicados oficiales.',
      );
    }
    return newsRepository.saveNewsItem(newsItem);
  }
}

class DeleteTournamentNewsUseCase {
  const DeleteTournamentNewsUseCase({required this.newsRepository});

  final TournamentNewsRepository newsRepository;

  Future<void> execute({
    required String newsItemId,
    required UserRole userRole,
  }) async {
    if (userRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los organizadores pueden eliminar noticias o comunicados oficiales.',
      );
    }
    return newsRepository.deleteNewsItem(newsItemId);
  }
}
