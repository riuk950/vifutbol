import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';

/// Immutable state container for the Championship Tournaments & Official Rules catalog.
class TournamentsCatalogState {
  const TournamentsCatalogState({
    required this.viewState,
    this.tournaments = const <ChampionshipTournament>[],
    this.selectedTournamentId,
    this.selectedFormatFilter,
    this.savedDraft,
    this.isSaving = false,
    this.lastFailure,
  });

  static const TournamentsCatalogState initial = TournamentsCatalogState(
    viewState: UiLoadingState<List<ChampionshipTournament>>(),
  );

  final UiViewState<List<ChampionshipTournament>> viewState;
  final List<ChampionshipTournament> tournaments;
  final String? selectedTournamentId;
  final TournamentFormat? selectedFormatFilter;
  final TournamentDraft? savedDraft;
  final bool isSaving;
  final AppFailure? lastFailure;

  bool get hasSavedDraft => savedDraft != null;

  /// Returns the list of tournaments filtered by [selectedFormatFilter].
  List<ChampionshipTournament> get filteredTournaments {
    if (selectedFormatFilter == null) return tournaments;
    return tournaments
        .where((tournament) => tournament.format == selectedFormatFilter)
        .toList();
  }

  /// Returns the currently selected tournament, or the first visible tournament if none is explicitly selected.
  ChampionshipTournament? get selectedTournament {
    final visible = filteredTournaments;
    if (visible.isEmpty) return null;
    if (selectedTournamentId != null) {
      for (final tournament in visible) {
        if (tournament.id == selectedTournamentId) {
          return tournament;
        }
      }
    }
    return visible.first;
  }

  TournamentsCatalogState copyWith({
    UiViewState<List<ChampionshipTournament>>? viewState,
    List<ChampionshipTournament>? tournaments,
    String? selectedTournamentId,
    bool clearSelectedTournament = false,
    TournamentFormat? selectedFormatFilter,
    bool clearFormatFilter = false,
    TournamentDraft? savedDraft,
    bool clearSavedDraft = false,
    bool? isSaving,
    AppFailure? lastFailure,
    bool clearLastFailure = false,
  }) {
    return TournamentsCatalogState(
      viewState: viewState ?? this.viewState,
      tournaments: tournaments ?? this.tournaments,
      selectedTournamentId: clearSelectedTournament
          ? null
          : (selectedTournamentId ?? this.selectedTournamentId),
      selectedFormatFilter: clearFormatFilter
          ? null
          : (selectedFormatFilter ?? this.selectedFormatFilter),
      savedDraft: clearSavedDraft ? null : (savedDraft ?? this.savedDraft),
      isSaving: isSaving ?? this.isSaving,
      lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}
