import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Central state notifier managing the championship tournaments catalog,
/// format filtering, status transitions, audited critical-rule updates,
/// and temporary local creation drafts.
class TournamentsController extends StateNotifier<TournamentsCatalogState> {
  TournamentsController({
    required this.tournamentsRepository,
    required this.manageTournamentsUseCase,
  }) : super(TournamentsCatalogState.initial) {
    loadCatalog();
  }

  final TournamentsRepository tournamentsRepository;
  final ManageTournamentsUseCase manageTournamentsUseCase;

  /// Loads persisted tournaments and any pending local creation draft.
  Future<void> loadCatalog() async {
    state = state.copyWith(
      viewState: const UiLoadingState<List<ChampionshipTournament>>(),
      clearLastFailure: true,
    );

    try {
      final tournaments = await tournamentsRepository.loadTournaments();
      final draft = await tournamentsRepository.loadDraft();
      final selectedId =
          state.selectedTournamentId ??
          (tournaments.isNotEmpty ? tournaments.first.id : null);

      if (tournaments.isEmpty) {
        state = state.copyWith(
          tournaments: tournaments,
          clearSelectedTournament: true,
          savedDraft: draft,
          clearSavedDraft: draft == null,
          viewState: const UiEmptyState<List<ChampionshipTournament>>(
            message: 'No hay campeonatos registrados',
            description:
                'Crea el primer campeonato oficial para centralizar su normativa, puntos y llaves.',
          ),
        );
      } else {
        state = state.copyWith(
          tournaments: tournaments,
          selectedTournamentId: selectedId,
          savedDraft: draft,
          clearSavedDraft: draft == null,
          viewState: UiContentState<List<ChampionshipTournament>>(tournaments),
        );
      }
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(
        viewState: UiErrorState<List<ChampionshipTournament>>(failure),
        lastFailure: failure,
      );
    }
  }

  /// Selects a championship tournament to inspect in detail.
  void selectTournament(String tournamentId) {
    state = state.copyWith(selectedTournamentId: tournamentId);
  }

  /// Sets or clears the competition format filter.
  void setFormatFilter(TournamentFormat? format) {
    if (format == null || state.selectedFormatFilter == format) {
      state = state.copyWith(clearFormatFilter: true);
    } else {
      state = state.copyWith(selectedFormatFilter: format);
    }
  }

  /// Saves a new or existing championship tournament with single-flight protection.
  Future<bool> saveTournament({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    ChampionshipTournament? existingTournament,
    bool confirmCriticalRuleOverride = false,
    String? auditReason,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final saved = await manageTournamentsUseCase.saveTournament(
        tournament: tournament,
        actorRole: actorRole,
        existingTournament: existingTournament,
        confirmCriticalRuleOverride: confirmCriticalRuleOverride,
        auditReason: auditReason,
      );

      final tournaments = await tournamentsRepository.loadTournaments();
      final draft = await tournamentsRepository.loadDraft();
      state = state.copyWith(
        tournaments: tournaments,
        selectedTournamentId: saved.id,
        savedDraft: draft,
        clearSavedDraft: draft == null,
        isSaving: false,
        viewState: UiContentState<List<ChampionshipTournament>>(tournaments),
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : TournamentValidationFailure(
              TournamentValidationErrorCode.invalidName,
              e.toString(),
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Transitions a championship tournament to [targetStatus].
  Future<bool> transitionTournamentStatus({
    required ChampionshipTournament tournament,
    required TournamentStatus targetStatus,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final updated = await manageTournamentsUseCase.transitionStatus(
        tournament: tournament,
        targetStatus: targetStatus,
        actorRole: actorRole,
      );
      final tournaments = await tournamentsRepository.loadTournaments();
      state = state.copyWith(
        tournaments: tournaments,
        selectedTournamentId: updated.id,
        isSaving: false,
        viewState: UiContentState<List<ChampionshipTournament>>(tournaments),
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Saves a temporary local creation draft.
  Future<void> saveDraft(TournamentDraft draft) async {
    await tournamentsRepository.saveDraft(draft);
    state = state.copyWith(savedDraft: draft);
  }

  /// Clears the temporary local creation draft.
  Future<void> clearDraft() async {
    await tournamentsRepository.clearDraft();
    state = state.copyWith(clearSavedDraft: true);
  }
}
