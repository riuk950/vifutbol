import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

class _MemoryStorage implements LocalStorageRepository {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _map[key];

  @override
  Future<void> writeString(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _map.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('TournamentsController', () {
    test(
      'loads catalog, filters by format, selects tournament, and manages drafts',
      () async {
        final repository = LocalTournamentsRepository(
          storage: _MemoryStorage(),
          config: EnvironmentConfig.development(),
        );
        await repository.saveTournament(
          ChampionshipTournament(
            id: 't-league',
            name: 'Liga ViFutbol',
            category: 'Libre',
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 9, 30),
            format: TournamentFormat.league,
            updatedAt: DateTime(2026, 5, 1),
          ),
        );
        await repository.saveTournament(
          ChampionshipTournament(
            id: 't-cup',
            name: 'Copa Relámpago',
            category: 'Libre',
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 9, 30),
            format: TournamentFormat.knockoutCup,
            updatedAt: DateTime(2026, 5, 1),
          ),
        );

        final controller = TournamentsController(
          tournamentsRepository: repository,
          manageTournamentsUseCase: ManageTournamentsUseCase(repository),
        );

        await controller.loadCatalog();
        expect(
          controller.state.viewState,
          isA<UiContentState<List<ChampionshipTournament>>>(),
        );
        expect(controller.state.tournaments.length, 2);

        controller.setFormatFilter(TournamentFormat.knockoutCup);
        expect(controller.state.filteredTournaments.length, 1);
        expect(
          controller.state.selectedTournament?.format,
          TournamentFormat.knockoutCup,
        );

        controller.setFormatFilter(TournamentFormat.knockoutCup);
        expect(controller.state.selectedFormatFilter, isNull);

        final draft = TournamentDraft(
          name: 'Borrador Clausura',
          category: 'Libre',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 8, 1),
          savedAt: DateTime(2026, 5, 1),
        );
        await controller.saveDraft(draft);
        expect(controller.state.hasSavedDraft, isTrue);

        await controller.clearDraft();
        expect(controller.state.hasSavedDraft, isFalse);
      },
    );

    test(
      'handles empty production catalog, creates tournament, transitions status, and enforces audit on inProgress',
      () async {
        final repository = LocalTournamentsRepository(
          storage: _MemoryStorage(),
          config: EnvironmentConfig.production(),
        );
        final controller = TournamentsController(
          tournamentsRepository: repository,
          manageTournamentsUseCase: ManageTournamentsUseCase(repository),
        );

        await controller.loadCatalog();
        expect(
          controller.state.viewState,
          isA<UiEmptyState<List<ChampionshipTournament>>>(),
        );

        final newTournament = ChampionshipTournament(
          id: 't-new-1',
          name: 'Torneo Apertura 2026',
          category: 'Primera',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 8, 1),
          format: TournamentFormat.league,
          updatedAt: DateTime(2026, 4, 17),
        );

        final createdOk = await controller.saveTournament(
          tournament: newTournament,
          actorRole: UserRole.organizer,
        );
        expect(createdOk, isTrue);
        expect(controller.state.tournaments.length, 1);

        final current = controller.state.selectedTournament!;
        final transitionedOk = await controller.transitionTournamentStatus(
          tournament: current,
          targetStatus: TournamentStatus.inProgress,
          actorRole: UserRole.organizer,
        );
        expect(transitionedOk, isTrue);
        expect(
          controller.state.selectedTournament?.status,
          TournamentStatus.inProgress,
        );

        // Attempt critical rule change without confirmation -> fails and exposes TournamentValidationFailure
        final inProgress = controller.state.selectedTournament!;
        final blocked = await controller.saveTournament(
          tournament: inProgress.copyWith(
            rules: const TournamentRulesConfig(pointsForWin: 2),
          ),
          existingTournament: inProgress,
          actorRole: UserRole.organizer,
        );
        expect(blocked, isFalse);
        expect(
          controller.state.lastFailure,
          isA<TournamentValidationFailure>(),
        );

        // Confirm with audit reason -> succeeds and records audit trail
        final confirmed = await controller.saveTournament(
          tournament: inProgress.copyWith(
            rules: const TournamentRulesConfig(pointsForWin: 2),
          ),
          existingTournament: inProgress,
          actorRole: UserRole.organizer,
          confirmCriticalRuleOverride: true,
          auditReason: 'Aprobación unánime comité técnico',
        );
        expect(confirmed, isTrue);
        expect(
          controller.state.selectedTournament?.auditTrail.single.reason,
          'Aprobación unánime comité técnico',
        );
      },
    );
  });
}
