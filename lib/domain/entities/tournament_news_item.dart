import 'tournament_news_category.dart';

/// Represents an official announcement, disciplinary bulletin, or rescheduling notice
/// published by a tournament organizer.
class TournamentNewsItem {
  final String id;
  final String tournamentId;
  final String title;
  final String body;
  final TournamentNewsCategory category;
  final DateTime publishedAt;
  final String authorUserId;
  final String authorName;
  final bool isPinned;

  TournamentNewsItem({
    required this.id,
    required this.tournamentId,
    required this.title,
    required this.body,
    required this.category,
    required this.publishedAt,
    required this.authorUserId,
    required this.authorName,
    this.isPinned = false,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'News item ID cannot be empty');
    }
    if (tournamentId.trim().isEmpty) {
      throw ArgumentError.value(
        tournamentId,
        'tournamentId',
        'Tournament ID cannot be empty',
      );
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 120) {
      throw ArgumentError.value(
        title,
        'title',
        'Title must be between 3 and 120 characters',
      );
    }
    final trimmedBody = body.trim();
    if (trimmedBody.length < 5 || trimmedBody.length > 3000) {
      throw ArgumentError.value(
        body,
        'body',
        'Body must be between 5 and 3000 characters',
      );
    }
    if (authorUserId.trim().isEmpty) {
      throw ArgumentError.value(
        authorUserId,
        'authorUserId',
        'Author User ID cannot be empty',
      );
    }
    if (authorName.trim().isEmpty) {
      throw ArgumentError.value(
        authorName,
        'authorName',
        'Author Name cannot be empty',
      );
    }
  }

  TournamentNewsItem copyWith({
    String? title,
    String? body,
    TournamentNewsCategory? category,
    DateTime? publishedAt,
    String? authorUserId,
    String? authorName,
    bool? isPinned,
  }) {
    return TournamentNewsItem(
      id: id,
      tournamentId: tournamentId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      authorUserId: authorUserId ?? this.authorUserId,
      authorName: authorName ?? this.authorName,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'title': title,
      'body': body,
      'category': category.name,
      'publishedAt': publishedAt.toIso8601String(),
      'authorUserId': authorUserId,
      'authorName': authorName,
      'isPinned': isPinned,
    };
  }

  factory TournamentNewsItem.fromJson(Map<String, dynamic> json) {
    return TournamentNewsItem(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: TournamentNewsCategory.fromString(json['category'] as String),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      authorUserId: json['authorUserId'] as String,
      authorName: json['authorName'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}
