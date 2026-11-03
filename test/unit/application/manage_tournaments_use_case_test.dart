import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

class _FakeStorage implements LocalStorageRepository {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  late LocalTournamentsRepository repository;
  late ManageTournamentsUseCase useCase;

  setUp(() {
    repository = LocalTournamentsRepository(
      storage: _FakeStorage(),
      config: EnvironmentConfig.production(),
    );
    useCase = ManageTournamentsUseCase(repository);
  });

  ChampionshipTournament buildValidTournament({
    TournamentFormat format = TournamentFormat.league,
    TournamentStatus status = TournamentStatus.openRegistration,
    TournamentRulesConfig rules = const TournamentRulesConfig(),
  }) {
    return ChampionshipTournament(
      id: 't-100',
      name: 'Torneo Clausura ViFutbol 2026',
      category: 'Libre Masculino',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 8, 30),
      format: format,
      status: status,
      rules: rules,
      updatedAt: DateTime(2026, 4, 17, 12, 0),
    );
  }

  group('ManageTournamentsUseCase - Role & Creation Validation (US1)', () {
    test('rejects creation when actorRole is not Organizer', () async {
      final candidate = buildValidTournament();

      for (final nonOrganizer in <UserRole>[
        UserRole.fan,
        UserRole.player,
        UserRole.coach,
        UserRole.referee,
      ]) {
        await expectLater(
          useCase.saveTournament(
            tournament: candidate,
            actorRole: nonOrganizer,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      }
    });

    test(
      'creates tournament with openRegistration status and clears creation draft',
      () async {
        await repository.saveDraft(
          TournamentDraft(
            name: 'Borrador temporal',
            category: 'Libre',
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 8, 1),
            savedAt: DateTime(2026, 4, 17),
          ),
        );
        expect(await repository.loadDraft(), isNotNull);

        final saved = await useCase.saveTournament(
          tournament: buildValidTournament(status: TournamentStatus.inProgress),
          actorRole: UserRole.organizer,
        );

        expect(saved.status, TournamentStatus.openRegistration);
        expect(await repository.loadDraft(), isNull);
      },
    );

    test(
      'validates name, category, dates, points, yellow cards, squad size, half duration, and group stage',
      () async {
        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament().copyWith(name: 'AB'),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidName,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament().copyWith(category: '   '),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidCategory,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament().copyWith(
              startDate: DateTime(2026, 9, 1),
              endDate: DateTime(2026, 8, 1),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidDateRange,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament(
              rules: const TournamentRulesConfig(
                pointsForWin: 1,
                pointsForDraw: 2,
                pointsForLoss: 0,
              ),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidPointsDistribution,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament(
              rules: const TournamentRulesConfig(yellowCardSuspensionLimit: 1),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidYellowCardLimit,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament(
              rules: const TournamentRulesConfig(
                minPlayersPerTeam: 15,
                maxPlayersPerTeam: 10,
              ),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidSquadSizeRange,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament(
              rules: const TournamentRulesConfig(halfDurationMinutes: 5),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidHalfDuration,
            ),
          ),
        );

        await expectLater(
          useCase.saveTournament(
            tournament: buildValidTournament(
              format: TournamentFormat.mixedGroupsAndKnockout,
              rules: const TournamentRulesConfig(
                groupStageConfig: GroupStageConfig(
                  groupCount: 9,
                  advancingPerGroup: 2,
                ),
              ),
            ),
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.invalidGroupStageConfig,
            ),
          ),
        );
      },
    );
  });

  group('ManageTournamentsUseCase - Status Machine & Audited Immutability (US2)', () {
    test(
      'blocks critical rule changes when inProgress unless confirmed with non-empty audit reason',
      () async {
        final created = await useCase.saveTournament(
          tournament: buildValidTournament(),
          actorRole: UserRole.organizer,
        );

        final inProgress = await useCase.transitionStatus(
          tournament: created,
          targetStatus: TournamentStatus.inProgress,
          actorRole: UserRole.organizer,
        );
        expect(inProgress.status, TournamentStatus.inProgress);

        // Non-critical rule edit (e.g., yellow card limit) succeeds without audit dialog
        final nonCriticalEdit = await useCase.saveTournament(
          tournament: inProgress.copyWith(
            rules: inProgress.rules.copyWith(yellowCardSuspensionLimit: 5),
          ),
          existingTournament: inProgress,
          actorRole: UserRole.organizer,
        );
        expect(nonCriticalEdit.rules.yellowCardSuspensionLimit, 5);
        expect(nonCriticalEdit.auditTrail, isEmpty);

        // Critical rule edit (scoring points) without confirmation is blocked
        final modifiedPoints = nonCriticalEdit.copyWith(
          rules: nonCriticalEdit.rules.copyWith(pointsForWin: 2),
        );
        await expectLater(
          useCase.saveTournament(
            tournament: modifiedPoints,
            existingTournament: nonCriticalEdit,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.criticalRulesImmutableWithoutAudit,
            ),
          ),
        );

        // Critical rule edit with confirmation and reason records RuleAuditEntry
        final auditedSave = await useCase.saveTournament(
          tournament: modifiedPoints,
          existingTournament: nonCriticalEdit,
          actorRole: UserRole.organizer,
          confirmCriticalRuleOverride: true,
          auditReason: 'Resolución oficial de asamblea de delegados',
        );
        expect(auditedSave.rules.pointsForWin, 2);
        expect(auditedSave.auditTrail.length, 1);
        expect(
          auditedSave.auditTrail.first.reason,
          'Resolución oficial de asamblea de delegados',
        );
        expect(
          auditedSave.auditTrail.first.summary,
          contains('Puntos (V/E/D): 3/1/0 -> 2/1/0'),
        );

        // Transition to finished locks all further edits
        final finished = await useCase.transitionStatus(
          tournament: auditedSave,
          targetStatus: TournamentStatus.finished,
          actorRole: UserRole.organizer,
        );
        await expectLater(
          useCase.saveTournament(
            tournament: finished.copyWith(name: 'Intento post-cierre'),
            existingTournament: finished,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TournamentValidationFailure>().having(
              (e) => e.code,
              'code',
              TournamentValidationErrorCode.tournamentAlreadyFinished,
            ),
          ),
        );
      },
    );
  });
}
