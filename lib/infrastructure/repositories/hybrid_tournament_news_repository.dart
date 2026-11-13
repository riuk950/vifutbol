import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `tournament_news`.
abstract interface class TournamentNewsRemoteDataSource {
  Future<List<TournamentNewsItem>> fetchForTournament(String tournamentId);
  Future<TournamentNewsItem> upsertNewsItem(TournamentNewsItem newsItem);
  Future<void> deleteById(String newsItemId);
  Future<void> replaceForTournament(
    String tournamentId,
    List<TournamentNewsItem> items,
  );
}

/// PostgREST implementation targeting `vifutboldev.tournament_news`.
class PostgrestTournamentNewsRemoteDataSource
    implements TournamentNewsRemoteDataSource {
  PostgrestTournamentNewsRemoteDataSource({
    required this.client,
    required this.schema,
  });

  final SupabaseClient client;
  final String schema;

  static String _toDbCategory(TournamentNewsCategory cat) => switch (cat) {
    TournamentNewsCategory.general => 'generalAnnouncement',
    TournamentNewsCategory.disciplinary => 'disciplinaryBulletin',
    TournamentNewsCategory.rescheduling => 'reschedulingNotice',
  };

  static TournamentNewsCategory _fromDbCategory(String? value) =>
      switch (value) {
        'generalAnnouncement' => TournamentNewsCategory.general,
        'disciplinaryBulletin' => TournamentNewsCategory.disciplinary,
        'reschedulingNotice' => TournamentNewsCategory.rescheduling,
        _ => TournamentNewsCategory.general,
      };

  static Map<String, dynamic> _toRow(TournamentNewsItem item) {
    return <String, dynamic>{
      'id': HybridRepositorySupport.ensureUuid(item.id, 'news'),
      'tournament_id': HybridRepositorySupport.ensureUuid(
        item.tournamentId,
        'tournament',
      ),
      'title': item.title,
      'body': item.body,
      'category': _toDbCategory(item.category),
      'published_at': item.publishedAt.toUtc().toIso8601String(),
      'author_user_id': HybridRepositorySupport.uuidOrNull(item.authorUserId),
      'author_name': item.authorName,
      'is_pinned': item.isPinned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static TournamentNewsItem _fromRow(Map<String, dynamic> r) {
    return TournamentNewsItem(
      id: r['id'] as String,
      tournamentId: r['tournament_id'] as String,
      title: r['title'] as String,
      body: r['body'] as String,
      category: _fromDbCategory(r['category'] as String?),
      publishedAt: DateTime.parse(r['published_at'] as String).toLocal(),
      authorUserId: (r['author_user_id'] as String?) ?? 'system-organizer',
      authorName: r['author_name'] as String,
      isPinned: r['is_pinned'] as bool? ?? false,
    );
  }

  @override
  Future<List<TournamentNewsItem>> fetchForTournament(
    String tournamentId,
  ) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final rows = await client
        .schema(schema)
        .from('tournament_news')
        .select()
        .eq('tournament_id', safeTournamentId)
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<TournamentNewsItem> upsertNewsItem(TournamentNewsItem newsItem) async {
    await client
        .schema(schema)
        .from('tournament_news')
        .upsert(_toRow(newsItem), onConflict: 'id');
    return newsItem;
  }

  @override
  Future<void> deleteById(String newsItemId) async {
    final safeId = HybridRepositorySupport.ensureUuid(newsItemId, 'news');
    await client
        .schema(schema)
        .from('tournament_news')
        .delete()
        .eq('id', safeId);
  }

  @override
  Future<void> replaceForTournament(
    String tournamentId,
    List<TournamentNewsItem> items,
  ) async {
    if (items.isEmpty) return;
    await client
        .schema(schema)
        .from('tournament_news')
        .upsert(items.map(_toRow).toList(), onConflict: 'id');
  }
}

/// Offline-first hybrid [TournamentNewsRepository].
class HybridTournamentNewsRepository implements TournamentNewsRepository {
  HybridTournamentNewsRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalTournamentNewsRepository local;
  final TournamentNewsRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<TournamentNewsItem>> loadNewsForTournament(String tournamentId) {
    return support.executeRead(
      remoteFetch: () => remote.fetchForTournament(tournamentId),
      cacheUpdate: (items) =>
          local.replaceNewsForTournament(tournamentId, items),
      localFallback: () => local.loadNewsForTournament(tournamentId),
    );
  }

  @override
  Stream<List<TournamentNewsItem>> watchNewsForTournament(String tournamentId) {
    loadNewsForTournament(tournamentId).ignore();
    return local.watchNewsForTournament(tournamentId);
  }

  @override
  Future<TournamentNewsItem> saveNewsItem(TournamentNewsItem newsItem) {
    return support.executeMutation(
      localWrite: () => local.saveNewsItem(newsItem),
      remoteWrite: () => remote.upsertNewsItem(newsItem),
      entityType: SyncOutboxEntityType.tournamentNews,
      entityId: newsItem.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'newsItem': newsItem.toJson()},
      displayTitle: newsItem.title,
    );
  }

  @override
  Future<void> deleteNewsItem(String newsItemId) {
    return support.executeMutation(
      localWrite: () => local.deleteNewsItem(newsItemId),
      remoteWrite: () => remote.deleteById(newsItemId),
      entityType: SyncOutboxEntityType.tournamentNews,
      entityId: newsItemId,
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {'newsItemId': newsItemId},
      displayTitle: newsItemId,
    );
  }

  @override
  Future<void> replaceNewsForTournament(
    String tournamentId,
    List<TournamentNewsItem> items,
  ) {
    return support.executeMutation(
      localWrite: () => local.replaceNewsForTournament(tournamentId, items),
      remoteWrite: () => remote.replaceForTournament(tournamentId, items),
      entityType: SyncOutboxEntityType.tournamentNews,
      entityId: tournamentId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': tournamentId,
        'items': items.map((i) => i.toJson()).toList(),
      },
      displayTitle: tournamentId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    switch (item.operation) {
      case SyncOutboxOperation.delete:
        await remote.deleteById(item.entityId);
      case SyncOutboxOperation.upsert:
        final raw = item.payloadJson['newsItem'];
        if (raw is Map) {
          await remote.upsertNewsItem(
            TournamentNewsItem.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      case SyncOutboxOperation.replaceBatch:
        final tournamentId = item.payloadJson['tournamentId'] as String? ?? '';
        final rawItems = (item.payloadJson['items'] as List<dynamic>?) ?? [];
        final items = rawItems
            .whereType<Map>()
            .map(
              (m) => TournamentNewsItem.fromJson(Map<String, dynamic>.from(m)),
            )
            .toList();
        await remote.replaceForTournament(tournamentId, items);
    }
  }
}
