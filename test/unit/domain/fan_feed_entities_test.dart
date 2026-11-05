import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';

void main() {
  group('TournamentNewsItem', () {
    final now = DateTime(2026, 11, 5, 10, 0);

    test('creates valid news item and converts to/from JSON', () {
      final item = TournamentNewsItem(
        id: 'news-1',
        tournamentId: 'tour-1',
        title: 'Boletín Oficial 1',
        body: 'Contenido oficial de prueba para el torneo.',
        category: TournamentNewsCategory.disciplinary,
        publishedAt: now,
        authorUserId: 'org-1',
        authorName: 'Comité Organizador',
        isPinned: true,
      );

      expect(item.id, 'news-1');
      expect(item.isPinned, isTrue);

      final json = item.toJson();
      final reconstructed = TournamentNewsItem.fromJson(json);

      expect(reconstructed.id, item.id);
      expect(reconstructed.title, item.title);
      expect(reconstructed.body, item.body);
      expect(reconstructed.category, TournamentNewsCategory.disciplinary);
      expect(reconstructed.isPinned, isTrue);
    });

    test('validates title and body constraints', () {
      expect(
        () => TournamentNewsItem(
          id: 'news-2',
          tournamentId: 'tour-1',
          title: 'ab', // too short (<3)
          body: 'Valid body text',
          category: TournamentNewsCategory.general,
          publishedAt: now,
          authorUserId: 'org-1',
          authorName: 'Organizador',
        ),
        throwsArgumentError,
      );

      expect(
        () => TournamentNewsItem(
          id: 'news-3',
          tournamentId: 'tour-1',
          title: 'Valid title',
          body: 'abc', // too short (<5)
          category: TournamentNewsCategory.general,
          publishedAt: now,
          authorUserId: 'org-1',
          authorName: 'Organizador',
        ),
        throwsArgumentError,
      );
    });
  });

  group('FanFavoriteTeam', () {
    test('creates favorite and serializes cleanly', () {
      final now = DateTime(2026, 11, 5, 9, 30);
      final favorite = FanFavoriteTeam(
        userId: 'user-1',
        tournamentId: 'tour-1',
        teamId: 'team-alpha',
        teamName: 'Alpha FC',
        notificationsEnabled: true,
        createdAt: now,
      );

      expect(favorite.teamName, 'Alpha FC');
      expect(favorite.notificationsEnabled, isTrue);

      final json = favorite.toJson();
      final deserialized = FanFavoriteTeam.fromJson(json);

      expect(deserialized.teamId, 'team-alpha');
      expect(deserialized.notificationsEnabled, isTrue);
    });
  });

  group('MatchLiveAlert', () {
    test('creates alert, updates read state and serializes cleanly', () {
      final now = DateTime(2026, 11, 5, 10, 15);
      final alert = MatchLiveAlert(
        id: 'alert-1',
        matchId: 'match-101',
        tournamentId: 'tour-1',
        type: MatchAlertType.goalScored,
        title: '¡Gol!',
        message: 'Gol de Alpha FC al minuto 34',
        timestamp: now,
        isRead: false,
      );

      expect(alert.isRead, isFalse);

      final readAlert = alert.copyWith(isRead: true);
      expect(readAlert.isRead, isTrue);

      final json = alert.toJson();
      final fromJson = MatchLiveAlert.fromJson(json);

      expect(fromJson.id, alert.id);
      expect(fromJson.type, MatchAlertType.goalScored);
      expect(fromJson.isRead, isFalse);
    });
  });
}
