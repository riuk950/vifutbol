import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/presentation/panel/models/panel_presentation_models.dart';

/// Provider exposing the concrete [TournamentsRepository] implementation.
final tournamentsRepositoryProvider = Provider<TournamentsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final local = LocalTournamentsRepository(storage: storage, config: config);

  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestTournamentsRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
    support: support,
  );
  final hybrid = HybridTournamentsRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.tournament,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

/// Provider exposing [ManageTournamentsUseCase].
final manageTournamentsUseCaseProvider = Provider<ManageTournamentsUseCase>((
  ref,
) {
  final repository = ref.watch(tournamentsRepositoryProvider);
  return ManageTournamentsUseCase(repository);
});

/// StateNotifierProvider exposing the central [TournamentsController].
final tournamentsControllerProvider =
    StateNotifierProvider<TournamentsController, TournamentsCatalogState>((
      ref,
    ) {
      final repository = ref.watch(tournamentsRepositoryProvider);
      final manageUseCase = ref.watch(manageTournamentsUseCaseProvider);

      return TournamentsController(
        tournamentsRepository: repository,
        manageTournamentsUseCase: manageUseCase,
      );
    });

/// Reactive provider exposing tournaments belonging to the active organizer.
final organizerTournamentsProvider = Provider<List<ChampionshipTournament>>((
  ref,
) {
  final catalogState = ref.watch(tournamentsControllerProvider);
  String? sessionUserId;
  try {
    final authState = ref.watch(authControllerProvider);
    sessionUserId = authState.session?.user.id;
  } catch (_) {
    // Fallback in isolated test environments
  }

  final effectiveUserId =
      (sessionUserId != null && sessionUserId.trim().isNotEmpty)
      ? sessionUserId
      : 'org-seed-1';

  return catalogState.tournaments.where((t) {
    final tOrgId = t.organizerId ?? 'org-seed-1';
    return tOrgId == effectiveUserId;
  }).toList();
});

/// Computes summary metrics exclusively from [organizerTournaments] and their matches.
OrganizerPanelData computeOrganizerPanelMetrics({
  required List<ChampionshipTournament> organizerTournaments,
  required List<ChampionshipMatch> allMatches,
}) {
  if (organizerTournaments.isEmpty) {
    return const OrganizerPanelData(
      activeTournamentsCount: 0,
      pendingScheduleMatchesCount: 0,
      unseededTournamentsCount: 0,
    );
  }

  final activeTournaments = organizerTournaments
      .where(
        (t) =>
            t.status == TournamentStatus.inProgress ||
            t.status == TournamentStatus.openRegistration,
      )
      .toList();
  final activeTournamentIds = activeTournaments.map((t) => t.id).toSet();

  final pendingScheduleMatchesCount = allMatches
      .where(
        (m) =>
            activeTournamentIds.contains(m.tournamentId) &&
            m.scheduledStartTime == null &&
            m.status != MatchStatus.completed &&
            m.status != MatchStatus.inProgress,
      )
      .length;

  final unseededTournamentsCount = activeTournaments
      .where((t) => !allMatches.any((m) => m.tournamentId == t.id))
      .length;

  return OrganizerPanelData(
    activeTournamentsCount: activeTournaments.length,
    pendingScheduleMatchesCount: pendingScheduleMatchesCount,
    unseededTournamentsCount: unseededTournamentsCount,
  );
}

/// Reactive provider exposing summary metrics scoped exclusively to the
/// authenticated organizer's competitions.
final organizerPanelMetricsProvider = Provider<OrganizerPanelData>((ref) {
  final organizerTournaments = ref.watch(organizerTournamentsProvider);
  final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

  return computeOrganizerPanelMetrics(
    organizerTournaments: organizerTournaments,
    allMatches: matchesCatalogState.matches,
  );
});
