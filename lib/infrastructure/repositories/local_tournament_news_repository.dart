import 'dart:async';
import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';

class LocalTournamentNewsRepository implements TournamentNewsRepository {
  LocalTournamentNewsRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  final StreamController<List<TournamentNewsItem>> _newsStreamController =
      StreamController<List<TournamentNewsItem>>.broadcast();

  static const String newsStorageKey = 'vifutbol.tournament_news.v1';

  @override
  Future<List<TournamentNewsItem>> loadNewsForTournament(
    String tournamentId,
  ) async {
    final all = await _loadAllNews();
    final tournamentNews = all
        .where((n) => n.tournamentId == tournamentId)
        .toList();
    _sortNews(tournamentNews);
    return tournamentNews;
  }

  @override
  Stream<List<TournamentNewsItem>> watchNewsForTournament(
    String tournamentId,
  ) async* {
    final initial = await loadNewsForTournament(tournamentId);
    yield initial;
    yield* _newsStreamController.stream.map((list) {
      final filtered = list
          .where((n) => n.tournamentId == tournamentId)
          .toList();
      _sortNews(filtered);
      return filtered;
    });
  }

  @override
  Future<TournamentNewsItem> saveNewsItem(TournamentNewsItem newsItem) async {
    final all = await _loadAllNews();
    final updated = List<TournamentNewsItem>.from(all);
    final index = updated.indexWhere((n) => n.id == newsItem.id);
    if (index >= 0) {
      updated[index] = newsItem;
    } else {
      updated.add(newsItem);
    }
    await _persistNews(updated);
    return newsItem;
  }

  @override
  Future<void> deleteNewsItem(String newsItemId) async {
    final all = await _loadAllNews();
    final updated = all.where((n) => n.id != newsItemId).toList();
    await _persistNews(updated);
  }

  @override
  Future<void> replaceNewsForTournament(
    String tournamentId,
    List<TournamentNewsItem> items,
  ) async {
    final all = await _loadAllNews();
    final otherNews = all.where((n) => n.tournamentId != tournamentId).toList();
    final updated = [...otherNews, ...items];
    await _persistNews(updated);
  }

  void _sortNews(List<TournamentNewsItem> items) {
    items.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });
  }

  Future<List<TournamentNewsItem>> _loadAllNews() async {
    try {
      final dynamic future = storage.readString(newsStorageKey);
      final raw = future is Future ? await future : null;
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TournamentNewsItem.fromJson)
            .toList();
      }
    } catch (_) {}

    if (config.environment == AppEnvironment.development) {
      final seeds = _buildSeedNews();
      await _persistNews(seeds);
      return seeds;
    }

    return const <TournamentNewsItem>[];
  }

  Future<void> _persistNews(List<TournamentNewsItem> items) async {
    final jsonList = items.map((n) => n.toJson()).toList();
    await storage.writeString(newsStorageKey, jsonEncode(jsonList));
    if (!_newsStreamController.isClosed) {
      _newsStreamController.add(items);
    }
  }

  List<TournamentNewsItem> _buildSeedNews() {
    return [
      TournamentNewsItem(
        id: 'news-seed-1',
        tournamentId: 'tournament-seed-liga-clausura',
        title: 'Inicio Oficial de la Liga Clausura 2026',
        body:
            'El comité organizador da la bienvenida a todos los clubes y aficionados al torneo Clausura. Se recuerda verificar canchas y horarios asignados en la pestaña Jornada.',
        category: TournamentNewsCategory.general,
        publishedAt: DateTime(2026, 5, 1, 9, 0),
        authorUserId: 'user-organizer-1',
        authorName: 'Comité Organizador ViFutbol',
        isPinned: true,
      ),
      TournamentNewsItem(
        id: 'news-seed-2',
        tournamentId: 'tournament-seed-liga-clausura',
        title: 'Boletín Disciplinario Jornada 1',
        body:
            'Resolución de amonestaciones y juego limpio correspondiente a los partidos inaugurales. Sin sanciones graves reportadas.',
        category: TournamentNewsCategory.disciplinary,
        publishedAt: DateTime(2026, 5, 2, 18, 30),
        authorUserId: 'user-organizer-1',
        authorName: 'Tribunal Deportivo ViFutbol',
        isPinned: false,
      ),
    ];
  }
}
