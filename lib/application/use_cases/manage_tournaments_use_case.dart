import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Use case that validates and persists championship tournaments, enforces
/// organizer permissions, manages lifecycle status transitions, and records
/// audited critical-rule modifications when a tournament is in progress.
class ManageTournamentsUseCase {
  const ManageTournamentsUseCase(this._repository);

  final TournamentsRepository _repository;

  /// Validates and saves a new or existing [ChampionshipTournament].
  ///
  /// Throws [UnauthorizedRoleFailure] if [actorRole] lacks [RoleCapability.manageTournaments].
  /// Throws [TournamentValidationFailure] if any domain rule or audit constraint is violated.
  Future<ChampionshipTournament> saveTournament({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    ChampionshipTournament? existingTournament,
    bool confirmCriticalRuleOverride = false,
    String? auditReason,
  }) async {
    _ensureOrganizerPermission(actorRole);

    if (existingTournament != null &&
        existingTournament.status == TournamentStatus.finished) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.tournamentAlreadyFinished,
        'Un campeonato finalizado no permite modificar su formato ni sus reglas oficiales',
      );
    }

    final trimmedName = tournament.name.trim();
    if (trimmedName.length < 3) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidName,
        'El nombre del campeonato debe tener al menos 3 caracteres',
      );
    }

    final trimmedCategory = tournament.category.trim();
    if (trimmedCategory.isEmpty) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidCategory,
        'Debes ingresar una categoría válida',
      );
    }

    if (tournament.endDate.isBefore(tournament.startDate)) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidDateRange,
        'La fecha de finalización no puede ser anterior a la fecha de inicio',
      );
    }

    final rules = tournament.rules;
    if (!rules.hasValidPointsDistribution) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidPointsDistribution,
        'Los puntos deben cumplir: Victoria > Empate >= Derrota >= 0',
      );
    }

    if (!rules.hasValidTiebreakerOrder) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidTiebreakerOrder,
        'El orden de criterios de desempate no puede estar vacío ni tener duplicados',
      );
    }

    if (!rules.hasValidYellowCardLimit) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidYellowCardLimit,
        'El límite de tarjetas amarillas debe estar entre 2 y 10',
      );
    }

    if (!rules.hasValidSquadSizeRange) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidSquadSizeRange,
        'El cupo de jugadores debe cumplir: 5 <= Mínimo <= Máximo <= 35',
      );
    }

    if (!rules.hasValidHalfDuration) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidHalfDuration,
        'La duración por tiempo debe estar entre 10 y 60 minutos',
      );
    }

    if (tournament.format == TournamentFormat.league &&
        !rules.hasValidLeagueRounds) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidLeagueRounds,
        'La Liga debe configurarse a 1 o 2 vueltas',
      );
    }

    if (tournament.format == TournamentFormat.mixedGroupsAndKnockout &&
        !rules.groupStageConfig.isValid) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidGroupStageConfig,
        'Configura entre 2 y 8 grupos y entre 1 y 4 clasificados por grupo',
      );
    }

    var updatedAuditTrail = List<RuleAuditEntry>.from(
      existingTournament?.auditTrail ?? tournament.auditTrail,
    );
    final effectiveStatus = existingTournament == null
        ? TournamentStatus.openRegistration
        : existingTournament.status;

    if (existingTournament != null &&
        existingTournament.status == TournamentStatus.inProgress &&
        existingTournament.hasCriticalRulesChanged(tournament)) {
      final trimmedReason = (auditReason ?? '').trim();
      if (!confirmCriticalRuleOverride || trimmedReason.isEmpty) {
        throw const TournamentValidationFailure(
          TournamentValidationErrorCode.criticalRulesImmutableWithoutAudit,
          'Se requiere confirmación administrativa explícita y motivo para alterar el formato o sistema de puntuación en curso',
        );
      }

      updatedAuditTrail.insert(
        0,
        RuleAuditEntry(
          recordedAt: tournament.updatedAt,
          summary: _buildAuditSummary(existingTournament, tournament),
          reason: trimmedReason,
          recalculationConfirmed: true,
        ),
      );
    }

    final prepared = tournament.copyWith(
      name: trimmedName,
      category: trimmedCategory,
      status: effectiveStatus,
      auditTrail: updatedAuditTrail,
    );

    final saved = await _repository.saveTournament(prepared);
    if (existingTournament == null) {
      await _repository.clearDraft();
    }
    return saved;
  }

  /// Transitions a championship tournament to [targetStatus].
  Future<ChampionshipTournament> transitionStatus({
    required ChampionshipTournament tournament,
    required TournamentStatus targetStatus,
    required UserRole actorRole,
  }) async {
    _ensureOrganizerPermission(actorRole);

    if (tournament.status == TournamentStatus.finished) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.tournamentAlreadyFinished,
        'Un campeonato finalizado no permite cambiar su estado',
      );
    }

    final updated = tournament.copyWith(
      status: targetStatus,
      updatedAt: DateTime.now(),
    );
    return _repository.saveTournament(updated);
  }

  void _ensureOrganizerPermission(UserRole actorRole) {
    final canManage = RolePermissionMatrix.hasCapability(
      actorRole,
      RoleCapability.manageTournaments,
    );
    if (!canManage) {
      throw const UnauthorizedRoleFailure();
    }
  }

  String _buildAuditSummary(
    ChampionshipTournament previous,
    ChampionshipTournament next,
  ) {
    final changes = <String>[];
    if (previous.format != next.format) {
      changes.add('Formato: ${previous.format.name} -> ${next.format.name}');
    }
    if (!previous.rules.hasSameScoringPoints(next.rules)) {
      changes.add(
        'Puntos (V/E/D): '
        '${previous.rules.pointsForWin}/${previous.rules.pointsForDraw}/${previous.rules.pointsForLoss} -> '
        '${next.rules.pointsForWin}/${next.rules.pointsForDraw}/${next.rules.pointsForLoss}',
      );
    }
    return changes.join(' · ');
  }
}
