import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/auth_providers.dart';
import '../../application/providers/digital_match_report_providers.dart';
import '../../application/use_cases/manage_digital_match_report_use_case.dart';
import '../../domain/entities/championship_match.dart';
import '../../domain/entities/match_report_enums.dart';
import '../../domain/entities/team_enums.dart';
import '../../domain/entities/user_role.dart';
import '../../l10n/app_localizations.dart';
import '../design_system/kick_pulse_colors.dart';
import '../design_system/kick_pulse_radii_spacing.dart';
import '../design_system/kick_pulse_typography.dart';
import '../design_system/widgets/kick_pulse_badge.dart';
import '../design_system/widgets/kick_pulse_card.dart';
import '../teams/widgets/kick_pulse_team_crest.dart';
import 'dialogs/close_match_report_confirmation_dialog.dart';
import 'dialogs/record_card_dialog.dart';
import 'dialogs/record_goal_dialog.dart';
import 'dialogs/record_substitution_dialog.dart';
import 'widgets/match_event_timeline_tile.dart';

/// Screen representing the live referee digital match report (/matches/report).
class DigitalMatchReportScreen extends ConsumerStatefulWidget {
  const DigitalMatchReportScreen({super.key, this.initialMatch});

  final ChampionshipMatch? initialMatch;

  @override
  ConsumerState<DigitalMatchReportScreen> createState() =>
      _DigitalMatchReportScreenState();
}

class _DigitalMatchReportScreenState
    extends ConsumerState<DigitalMatchReportScreen> {
  Timer? _ticker;
  late DateTime _now;
  late final TextEditingController _observationsController;
  String? _lastSyncedObservations;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _observationsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMatch != null) {
        final activeRole = ref.read(activeUserRoleProvider);
        ref
            .read(digitalMatchReportControllerProvider.notifier)
            .loadReportForMatch(widget.initialMatch!, activeRole: activeRole);
      }
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _observationsController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(digitalMatchReportControllerProvider);
    final controller = ref.read(digitalMatchReportControllerProvider.notifier);
    final activeRole = ref.watch(activeUserRoleProvider);
    final authState = ref.watch(authControllerProvider);

    final match = state.match ?? widget.initialMatch;
    final report = state.report;

    if (state.isLoading || match == null || report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acta del Partido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (report.refereeObservations != _lastSyncedObservations) {
      _lastSyncedObservations = report.refereeObservations;
      if (_observationsController.text.isEmpty &&
          report.refereeObservations != null) {
        _observationsController.text = report.refereeObservations!;
      }
    }

    final actorUserId = authState.session?.user.id;
    final actorRefereeId = authState.session?.user.roleProfile?.linkedRefereeId;
    final bool isAssignedOrOrganizer =
        ManageDigitalMatchReportUseCase.isMatchAssignedToActor(
      match,
      activeRole: activeRole,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );
    final bool canEdit = isAssignedOrOrganizer && !report.isClosed;

    final homeName = state.homeTeam?.name ?? match.homeTeamId;
    final awayName = state.awayTeam?.name ?? match.awayTeamId;

    final totalElapsedSeconds = report.totalElapsedSecondsAt(_now);
    final currentMinute = report.currentMatchMinuteAt(_now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta Digital del Árbitro'),
        actions: [
          // Offline mode toggle for testing and field contingency
          IconButton(
            key: const Key('digital_match_report_offline_toggle'),
            icon: Icon(
              state.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
              color: state.isOfflineMode
                  ? Colors.amberAccent
                  : KickPulseColors.accentPrimary,
            ),
            tooltip: state.isOfflineMode
                ? 'Modo sin conexión activo (Toca para reconectar)'
                : 'Conexión activa (Toca para simular modo sin conexión)',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () {
              if (state.isOfflineMode) {
                controller.synchronizeOfflineQueue();
              } else {
                controller.setOfflineMode(true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline Banner when in offline mode
            if (state.isOfflineMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                  vertical: KickPulseRadiiSpacing.spaceSm,
                ),
                color: Colors.amber.shade900,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Modo sin conexión: cambios guardados en el dispositivo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (state.pendingSyncEventsCount > 0)
                      TextButton.icon(
                        icon: const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          'Sincronizar (${state.pendingSyncEventsCount})',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: state.isSubmitting
                            ? null
                            : () => controller.synchronizeOfflineQueue(),
                      ),
                  ],
                ),
              ),

            // Unauthorized referee read-only banner
            if (!isAssignedOrOrganizer && !report.isClosed)
              Container(
                key: const Key('digital_match_report_unauthorized_banner'),
                width: double.infinity,
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                color: KickPulseColors.accentLive.withValues(alpha: 0.16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: KickPulseColors.accentLive,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.refereeMatchUnauthorizedBanner,
                        style: const TextStyle(
                          color: KickPulseColors.accentLive,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Non-blocking unconfirmed convocation fallback banner
            if (canEdit && state.hasUnconfirmedConvocation)
              Container(
                key: const Key(
                  'digital_match_report_unconfirmed_convocation_banner',
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                color: KickPulseColors.accentWarning.withValues(alpha: 0.16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: KickPulseColors.accentWarning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.refereeMatchUnconfirmedConvocationBanner,
                        style: const TextStyle(
                          color: KickPulseColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Error banner if any
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                color: KickPulseColors.accentLive.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: KickPulseColors.accentLive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: KickPulseColors.accentLive,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Live Scoreboard Header
            Padding(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
              child: KickPulseCard(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
                child: Column(
                  children: [
                    // Period status badge & clock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (report.currentPeriod.isRunning)
                          const KickPulseBadge(
                            label: 'EN JUEGO',
                            variant: KickPulseBadgeVariant.live,
                          )
                        else if (report.isClosed)
                          const KickPulseBadge(
                            label: 'FINALIZADO',
                            variant: KickPulseBadgeVariant.info,
                          )
                        else
                          KickPulseBadge(
                            label: _periodLabel(report.currentPeriod),
                            variant: KickPulseBadgeVariant.neutral,
                          ),
                        Text(
                          _formatTimer(totalElapsedSeconds),
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                    // Teams & Tabular Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Home Team
                        Expanded(
                          child: Column(
                            children: [
                              KickPulseTeamCrest(
                                shortCode:
                                    state.homeTeam?.shortCode ??
                                    (homeName.length >= 3
                                        ? homeName.substring(0, 3)
                                        : homeName),
                                crestShape:
                                    state.homeTeam?.crestShape ??
                                    TeamCrestShape.shield,
                                primaryColorHex:
                                    state.homeTeam?.primaryColorHex ??
                                    0xFF10B981,
                                secondaryColorHex:
                                    state.homeTeam?.secondaryColorHex ??
                                    0xFF065F46,
                                size: 48,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                homeName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: KickPulseTypography.cardTitle.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tabular Score
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KickPulseRadiiSpacing.spaceMd,
                          ),
                          child: Text(
                            '${report.homeScore}  -  ${report.awayScore}',
                            style: KickPulseTypography.displayScore.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        // Away Team
                        Expanded(
                          child: Column(
                            children: [
                              KickPulseTeamCrest(
                                shortCode:
                                    state.awayTeam?.shortCode ??
                                    (awayName.length >= 3
                                        ? awayName.substring(0, 3)
                                        : awayName),
                                crestShape:
                                    state.awayTeam?.crestShape ??
                                    TeamCrestShape.shield,
                                primaryColorHex:
                                    state.awayTeam?.primaryColorHex ??
                                    0xFF2979FF,
                                secondaryColorHex:
                                    state.awayTeam?.secondaryColorHex ??
                                    0xFF1A237E,
                                size: 48,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                awayName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: KickPulseTypography.cardTitle.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Referee Period Controls
            if (canEdit)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                ),
                child: Row(
                  children: [
                    if (report.currentPeriod == MatchPeriod.notStarted)
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar Partido'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KickPulseColors.accentPrimary,
                            foregroundColor: KickPulseColors.canvasBackground,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () => controller.transitionPeriod(
                                  MatchPeriod.firstHalf,
                                  activeRole: activeRole,
                                  actorUserId: actorUserId,
                                  actorRefereeId: actorRefereeId,
                                ),
                        ),
                      ),
                    if (report.currentPeriod == MatchPeriod.firstHalf)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Fin 1er Tiempo'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () => controller.transitionPeriod(
                                  MatchPeriod.halfTime,
                                  activeRole: activeRole,
                                  actorUserId: actorUserId,
                                  actorRefereeId: actorRefereeId,
                                ),
                        ),
                      ),
                    if (report.currentPeriod == MatchPeriod.halfTime)
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar 2do Tiempo'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KickPulseColors.accentPrimary,
                            foregroundColor: KickPulseColors.canvasBackground,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () => controller.transitionPeriod(
                                  MatchPeriod.secondHalf,
                                  activeRole: activeRole,
                                  actorUserId: actorUserId,
                                  actorRefereeId: actorRefereeId,
                                ),
                        ),
                      ),
                    if (report.currentPeriod == MatchPeriod.secondHalf) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.timer_off),
                          label: const Text('Tiempo Cumplido'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () => controller.transitionPeriod(
                                  MatchPeriod.fullTime,
                                  activeRole: activeRole,
                                  actorUserId: actorUserId,
                                  actorRefereeId: actorRefereeId,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (report.currentPeriod == MatchPeriod.secondHalf ||
                        report.currentPeriod == MatchPeriod.fullTime)
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.assignment_turned_in),
                          label: const Text('Cerrar Acta Oficial'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KickPulseColors.accentElectric,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () => _openCloseReportDialog(
                                  context,
                                  match,
                                  report,
                                  homeName,
                                  awayName,
                                  controller,
                                  activeRole,
                                  actorUserId ?? 'ref-seed-1',
                                  actorRefereeId,
                                ),
                        ),
                      ),
                  ],
                ),
              ),

            // Quick Actions Bar (Goles, Tarjetas, Sustitución)
            if (canEdit && report.currentPeriod.isOpenForEvents) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.sports_soccer, size: 18),
                        label: const Text('Gol'),
                        style: FilledButton.styleFrom(
                          backgroundColor: KickPulseColors.accentLive,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: state.isSubmitting
                            ? null
                            : () => _openRecordGoalDialog(
                                context,
                                match,
                                report,
                                homeName,
                                awayName,
                                state.homeEligiblePlayers,
                                state.awayEligiblePlayers,
                                currentMinute,
                                controller,
                                activeRole,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.style, size: 18),
                        label: const Text('Amarilla'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: state.isSubmitting
                            ? null
                            : () => _openRecordCardDialog(
                                context,
                                match,
                                report,
                                homeName,
                                awayName,
                                state.homeEligiblePlayers,
                                state.awayEligiblePlayers,
                                currentMinute,
                                controller,
                                activeRole,
                                false,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.dangerous, size: 18),
                        label: const Text('Roja'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: state.isSubmitting
                            ? null
                            : () => _openRecordCardDialog(
                                context,
                                match,
                                report,
                                homeName,
                                awayName,
                                state.homeEligiblePlayers,
                                state.awayEligiblePlayers,
                                currentMinute,
                                controller,
                                activeRole,
                                true,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Sustitución',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: state.isSubmitting
                          ? null
                          : () => _openRecordSubstitutionDialog(
                              context,
                              match,
                              report,
                              homeName,
                              awayName,
                              state.homeEligiblePlayers,
                              state.awayEligiblePlayers,
                              currentMinute,
                              controller,
                              activeRole,
                            ),
                    ),
                  ],
                ),
              ),
            ],

            // Referee Observations Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceMd,
              ),
              child: KickPulseCard(
                key: const Key('digital_match_report_observations_card'),
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.refereeObservationsTitle,
                      style: KickPulseTypography.cardTitle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                    if (canEdit) ...[
                      TextField(
                        key: const Key('digital_match_report_observations_field'),
                        controller: _observationsController,
                        maxLines: 2,
                        style: KickPulseTypography.bodyPrimary.copyWith(
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.refereeObservationsHint,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          key: const Key(
                            'digital_match_report_save_observations_button',
                          ),
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: Text(l10n.refereeObservationsSaveAction),
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  final saved =
                                      await controller.updateObservations(
                                    activeRole: activeRole,
                                    observations: _observationsController.text,
                                    actorUserId: actorUserId,
                                    actorRefereeId: actorRefereeId,
                                  );
                                  if (saved && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.refereeObservationsSavedMessage,
                                        ),
                                        backgroundColor:
                                            KickPulseColors.accentPrimary,
                                      ),
                                    );
                                  }
                                },
                        ),
                      ),
                    ] else
                      Text(
                        (report.refereeObservations != null &&
                                report.refereeObservations!.trim().isNotEmpty)
                            ? report.refereeObservations!
                            : l10n.refereeObservationsEmpty,
                        style: KickPulseTypography.captionMeta,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            const Divider(),

            // Timeline Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceMd,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Línea de Tiempo (${report.events.length})',
                    style: KickPulseTypography.cardTitle.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),

            // Timeline List (Reverse Chronological)
            Expanded(
              child: report.events.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay incidencias registradas aún en el partido.',
                        style: KickPulseTypography.captionMeta,
                      ),
                    )
                  : ListView.builder(
                      itemCount: report.events.length,
                      itemBuilder: (context, index) {
                        // Reverse chronological order
                        final event =
                            report.events[report.events.length - 1 - index];
                        return MatchEventTimelineTile(
                          event: event,
                          canUndo: canEdit && !report.isClosed,
                          onUndo: () => _confirmUndoEvent(
                            context,
                            event.id,
                            controller,
                            activeRole,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(MatchPeriod period) {
    switch (period) {
      case MatchPeriod.notStarted:
        return 'Por Iniciar';
      case MatchPeriod.firstHalf:
        return 'Primer Tiempo';
      case MatchPeriod.halfTime:
        return 'Descanso';
      case MatchPeriod.secondHalf:
        return 'Segundo Tiempo';
      case MatchPeriod.fullTime:
        return 'Tiempo Cumplido';
      case MatchPeriod.closed:
        return 'Acta Cerrada';
    }
  }

  void _openRecordGoalDialog(
    BuildContext context,
    ChampionshipMatch match,
    var report,
    String homeName,
    String awayName,
    var homePlayers,
    var awayPlayers,
    int minute,
    var controller,
    UserRole activeRole,
  ) {
    showDialog(
      context: context,
      builder: (_) => RecordGoalDialog(
        homeTeamId: match.homeTeamId,
        homeTeamName: homeName,
        awayTeamId: match.awayTeamId,
        awayTeamName: awayName,
        homePlayers: homePlayers,
        awayPlayers: awayPlayers,
        expelledPlayerIds: report.expelledPlayerIds,
        initialMinute: minute,
        onConfirm: (teamId, scorer, assistant, min, notes) {
          controller.recordGoal(
            activeRole: activeRole,
            teamId: teamId,
            scorer: scorer,
            assistant: assistant,
            minute: min,
            notes: notes,
          );
        },
      ),
    );
  }

  void _openRecordCardDialog(
    BuildContext context,
    ChampionshipMatch match,
    var report,
    String homeName,
    String awayName,
    var homePlayers,
    var awayPlayers,
    int minute,
    var controller,
    UserRole activeRole,
    bool isDirectRed,
  ) {
    showDialog(
      context: context,
      builder: (_) => RecordCardDialog(
        homeTeamId: match.homeTeamId,
        homeTeamName: homeName,
        awayTeamId: match.awayTeamId,
        awayTeamName: awayName,
        homePlayers: homePlayers,
        awayPlayers: awayPlayers,
        report: report,
        initialMinute: minute,
        initialIsDirectRed: isDirectRed,
        onConfirm: (teamId, player, isRed, min, notes) {
          controller.recordCard(
            activeRole: activeRole,
            teamId: teamId,
            player: player,
            isDirectRed: isRed,
            minute: min,
            notes: notes,
          );
        },
      ),
    );
  }

  void _openRecordSubstitutionDialog(
    BuildContext context,
    ChampionshipMatch match,
    var report,
    String homeName,
    String awayName,
    var homePlayers,
    var awayPlayers,
    int minute,
    var controller,
    UserRole activeRole,
  ) {
    showDialog(
      context: context,
      builder: (_) => RecordSubstitutionDialog(
        homeTeamId: match.homeTeamId,
        homeTeamName: homeName,
        awayTeamId: match.awayTeamId,
        awayTeamName: awayName,
        homePlayers: homePlayers,
        awayPlayers: awayPlayers,
        expelledPlayerIds: report.expelledPlayerIds,
        initialMinute: minute,
        onConfirm: (teamId, playerOut, playerIn, min, notes) {
          controller.recordSubstitution(
            activeRole: activeRole,
            teamId: teamId,
            playerOut: playerOut,
            playerIn: playerIn,
            minute: min,
            notes: notes,
          );
        },
      ),
    );
  }

  void _confirmUndoEvent(
    BuildContext context,
    String eventId,
    var controller,
    UserRole activeRole,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Anular incidencia del acta?'),
        content: const Text(
          'Se recalculará el marcador y el estado de sanciones del partido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KickPulseColors.accentLive,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.removeEvent(eventId, activeRole: activeRole);
            },
            child: const Text('Anular Incidencia'),
          ),
        ],
      ),
    );
  }

  void _openCloseReportDialog(
    BuildContext context,
    ChampionshipMatch match,
    var report,
    String homeName,
    String awayName,
    var controller,
    UserRole activeRole,
    String userId,
    String? actorRefereeId,
  ) {
    showDialog(
      context: context,
      builder: (_) => CloseMatchReportConfirmationDialog(
        match: match,
        report: report,
        homeTeamName: homeName,
        awayTeamName: awayName,
        onConfirmClose: () {
          controller.closeReport(
            activeRole: activeRole,
            userId: userId,
            actorRefereeId: actorRefereeId,
          );
        },
      ),
    );
  }
}
