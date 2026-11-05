import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/manage_tournament_news_use_cases.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';

class TournamentNewsState {
  final List<TournamentNewsItem> news;
  final TournamentNewsCategory? categoryFilter;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const TournamentNewsState({
    this.news = const [],
    this.categoryFilter,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  List<TournamentNewsItem> get filteredNews {
    if (categoryFilter == null) return news;
    return news.where((item) => item.category == categoryFilter).toList();
  }

  TournamentNewsState copyWith({
    List<TournamentNewsItem>? news,
    TournamentNewsCategory? Function()? categoryFilter,
    bool? isLoading,
    bool? isSaving,
    String? Function()? errorMessage,
  }) {
    return TournamentNewsState(
      news: news ?? this.news,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TournamentNewsController extends StateNotifier<TournamentNewsState> {
  TournamentNewsController({
    required this.newsRepository,
    required this.publishUseCase,
    required this.deleteUseCase,
  }) : super(const TournamentNewsState());

  final TournamentNewsRepository newsRepository;
  final PublishTournamentNewsUseCase publishUseCase;
  final DeleteTournamentNewsUseCase deleteUseCase;

  StreamSubscription<List<TournamentNewsItem>>? _newsSubscription;

  Future<void> loadNews(String tournamentId) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    await _newsSubscription?.cancel();

    _newsSubscription = newsRepository
        .watchNewsForTournament(tournamentId)
        .listen(
          (items) {
            state = state.copyWith(news: items, isLoading: false);
          },
          onError: (dynamic error) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: () =>
                  error is AppFailure ? error.message : error.toString(),
            );
          },
        );
  }

  void setCategoryFilter(TournamentNewsCategory? category) {
    state = state.copyWith(categoryFilter: () => category);
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: () => null);
  }

  Future<bool> publishNews({
    required TournamentNewsItem item,
    required UserRole userRole,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await publishUseCase.execute(newsItem: item, userRole: userRole);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteNews({
    required String newsItemId,
    required UserRole userRole,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await deleteUseCase.execute(newsItemId: newsItemId, userRole: userRole);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _newsSubscription?.cancel();
    super.dispose();
  }
}
