import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_rules_summary_card.dart';
import 'package:vifutbol/presentation/venues/widgets/create_venue_bottom_sheet.dart';

/// Screen for creating a new championship tournament or editing an existing one,
/// including custom rules, audited critical-rule protection when in progress,
/// and local mobile draft preservation.
class TournamentFormScreen extends ConsumerStatefulWidget {
  const TournamentFormScreen({super.key, this.initialTournament});

  final ChampionshipTournament? initialTournament;

  @override
  ConsumerState<TournamentFormScreen> createState() =>
      _TournamentFormScreenState();
}

class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _winPointsController;
  late final TextEditingController _drawPointsController;
  late final TextEditingController _lossPointsController;
  late final TextEditingController _yellowCardsController;
  late final TextEditingController _minPlayersController;
  late final TextEditingController _maxPlayersController;
  late final TextEditingController _halfDurationController;
  late final TextEditingController _groupCountController;
  late final TextEditingController _advancingPerGroupController;

  late DateTime _startDate;
  late DateTime _endDate;
  late TournamentFormat _format;
  late int _leagueRounds;
  late KnockoutRound _startingRound;
  late bool _twoLeggedTies;
  late bool _directPenaltyShootout;
  late List<TiebreakerCriterion> _tiebreakerOrder;
  late List<String> _selectedVenueIds;

  AppLifecycleListener? _lifecycleListener;
  bool _isDirty = false;
  bool _restoredFromDraft = false;
  String? _validationErrorMessage;

  bool get _isEditMode => widget.initialTournament != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialTournament;
    final draft = existing == null
        ? ref.read(tournamentsControllerProvider).savedDraft
        : null;

    if (existing != null) {
      _initFields(
        name: existing.name,
        category: existing.category,
        startDate: existing.startDate,
        endDate: existing.endDate,
        format: existing.format,
        rules: existing.rules,
        venueIds: existing.venueIds,
      );
    } else if (draft != null) {
      _restoredFromDraft = true;
      _initFields(
        name: draft.name,
        category: draft.category,
        startDate: draft.startDate,
        endDate: draft.endDate,
        format: draft.format,
        rules: draft.rules,
        venueIds: draft.venueIds,
      );
    } else {
      _initFields(
        name: '',
        category: 'Libre Masculino',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 8, 30),
        format: TournamentFormat.league,
        rules: const TournamentRulesConfig(),
        venueIds: const <String>[],
      );
    }

    _lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        if (!_isEditMode &&
            _isDirty &&
            (state == AppLifecycleState.inactive ||
                state == AppLifecycleState.paused ||
                state == AppLifecycleState.hidden)) {
          _persistLocalDraft();
        }
      },
    );
  }

  void _initFields({
    required String name,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    required TournamentFormat format,
    required TournamentRulesConfig rules,
    required List<String> venueIds,
  }) {
    _nameController = TextEditingController(text: name)
      ..addListener(_markDirty);
    _categoryController = TextEditingController(text: category)
      ..addListener(_markDirty);
    _winPointsController = TextEditingController(
      text: rules.pointsForWin.toString(),
    )..addListener(_markDirty);
    _drawPointsController = TextEditingController(
      text: rules.pointsForDraw.toString(),
    )..addListener(_markDirty);
    _lossPointsController = TextEditingController(
      text: rules.pointsForLoss.toString(),
    )..addListener(_markDirty);
    _yellowCardsController = TextEditingController(
      text: rules.yellowCardSuspensionLimit.toString(),
    )..addListener(_markDirty);
    _minPlayersController = TextEditingController(
      text: rules.minPlayersPerTeam.toString(),
    )..addListener(_markDirty);
    _maxPlayersController = TextEditingController(
      text: rules.maxPlayersPerTeam.toString(),
    )..addListener(_markDirty);
    _halfDurationController = TextEditingController(
      text: rules.halfDurationMinutes.toString(),
    )..addListener(_markDirty);
    _groupCountController = TextEditingController(
      text: rules.groupStageConfig.groupCount.toString(),
    )..addListener(_markDirty);
    _advancingPerGroupController = TextEditingController(
      text: rules.groupStageConfig.advancingPerGroup.toString(),
    )..addListener(_markDirty);

    _startDate = startDate;
    _endDate = endDate;
    _format = format;
    _leagueRounds = rules.leagueRounds;
    _startingRound = rules.knockoutConfig.startingRound;
    _twoLeggedTies = rules.knockoutConfig.twoLeggedTies;
    _directPenaltyShootout = rules.knockoutConfig.directPenaltyShootoutOnDraw;
    _tiebreakerOrder = List<TiebreakerCriterion>.from(rules.tiebreakerOrder);
    _selectedVenueIds = List<String>.from(venueIds);
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _lossPointsController.dispose();
    _yellowCardsController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _halfDurationController.dispose();
    _groupCountController.dispose();
    _advancingPerGroupController.dispose();
    super.dispose();
  }

  TournamentRulesConfig _buildRulesFromInputs() {
    return TournamentRulesConfig(
      pointsForWin: int.tryParse(_winPointsController.text.trim()) ?? -1,
      pointsForDraw: int.tryParse(_drawPointsController.text.trim()) ?? -1,
      pointsForLoss: int.tryParse(_lossPointsController.text.trim()) ?? -1,
      tiebreakerOrder: List<TiebreakerCriterion>.from(_tiebreakerOrder),
      yellowCardSuspensionLimit:
          int.tryParse(_yellowCardsController.text.trim()) ?? 0,
      minPlayersPerTeam: int.tryParse(_minPlayersController.text.trim()) ?? 0,
      maxPlayersPerTeam: int.tryParse(_maxPlayersController.text.trim()) ?? 0,
      halfDurationMinutes:
          int.tryParse(_halfDurationController.text.trim()) ?? 0,
      leagueRounds: _leagueRounds,
      knockoutConfig: KnockoutStageConfig(
        startingRound: _startingRound,
        twoLeggedTies: _twoLeggedTies,
        directPenaltyShootoutOnDraw: _directPenaltyShootout,
      ),
      groupStageConfig: GroupStageConfig(
        groupCount: int.tryParse(_groupCountController.text.trim()) ?? 0,
        advancingPerGroup:
            int.tryParse(_advancingPerGroupController.text.trim()) ?? 0,
      ),
    );
  }

  ChampionshipTournament _buildCandidateTournament() {
    final existing = widget.initialTournament;
    var currentUserId = 'org-seed-1';
    try {
      currentUserId =
          ref.read(authControllerProvider).session?.user.id ?? 'org-seed-1';
    } catch (_) {
      // In isolated tests where auth controller is not overridden in ProviderScope
    }

    return ChampionshipTournament(
      id: existing?.id ?? 'tournament-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      format: _format,
      status: existing?.status ?? TournamentStatus.openRegistration,
      rules: _buildRulesFromInputs(),
      auditTrail: existing?.auditTrail ?? const [],
      updatedAt: DateTime.now(),
      organizerId: existing?.organizerId ?? currentUserId,
      venueIds: List<String>.unmodifiable(_selectedVenueIds),
    );
  }

  Future<void> _persistLocalDraft() async {
    final draft = TournamentDraft(
      name: _nameController.text,
      category: _categoryController.text,
      startDate: _startDate,
      endDate: _endDate,
      format: _format,
      rules: _buildRulesFromInputs(),
      savedAt: DateTime.now(),
      venueIds: List<String>.unmodifiable(_selectedVenueIds),
    );
    await ref.read(tournamentsControllerProvider.notifier).saveDraft(draft);
  }

  Future<void> _handleCreateNewVenue() async {
    final newVenue = await showCreateVenueBottomSheet(context);
    if (newVenue != null && mounted) {
      setState(() {
        if (!_selectedVenueIds.contains(newVenue.id)) {
          _selectedVenueIds.add(newVenue.id);
        }
        _isDirty = true;
      });
    }
  }

  String? _validateCandidate(
    ChampionshipTournament candidate,
    AppLocalizations l10n,
  ) {
    if (candidate.name.length < 3) {
      return l10n.tournamentErrorInvalidName;
    }
    if (candidate.category.isEmpty) {
      return l10n.tournamentErrorInvalidCategory;
    }
    if (candidate.endDate.isBefore(candidate.startDate)) {
      return l10n.tournamentErrorInvalidDates;
    }
    if (!candidate.rules.hasValidPointsDistribution) {
      return l10n.tournamentErrorInvalidPoints;
    }
    if (!candidate.rules.hasValidYellowCardLimit) {
      return l10n.tournamentErrorInvalidYellowCards;
    }
    if (!candidate.rules.hasValidSquadSizeRange) {
      return l10n.tournamentErrorInvalidSquadSize;
    }
    if (!candidate.rules.hasValidHalfDuration) {
      return l10n.tournamentErrorInvalidHalfDuration;
    }
    if (candidate.format == TournamentFormat.mixedGroupsAndKnockout &&
        !candidate.rules.groupStageConfig.isValid) {
      return l10n.tournamentErrorInvalidGroupStage;
    }
    return null;
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    final candidate = _buildCandidateTournament();
    final validationError = _validateCandidate(candidate, l10n);
    if (validationError != null) {
      setState(() {
        _validationErrorMessage = validationError;
      });
      return;
    }

    setState(() {
      _validationErrorMessage = null;
    });

    final existing = widget.initialTournament;
    var confirmCriticalOverride = false;
    String? auditReason;

    if (existing != null &&
        existing.status == TournamentStatus.inProgress &&
        existing.hasCriticalRulesChanged(candidate)) {
      final enteredReason = await _showAuditConfirmationDialog(l10n);
      if (enteredReason == null) {
        return;
      }
      confirmCriticalOverride = true;
      auditReason = enteredReason;
    }

    final activeRole = ref.read(activeUserRoleProvider);
    final saved = await ref
        .read(tournamentsControllerProvider.notifier)
        .saveTournament(
          tournament: candidate,
          actorRole: activeRole,
          existingTournament: existing,
          confirmCriticalRuleOverride: confirmCriticalOverride,
          auditReason: auditReason,
          venueIds: _selectedVenueIds,
        );

    if (!mounted) return;

    if (saved) {
      setState(() {
        _isDirty = false;
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } else {
      final failure = ref.read(tournamentsControllerProvider).lastFailure;
      setState(() {
        _validationErrorMessage = failure?.message;
      });
    }
  }

  Future<String?> _showAuditConfirmationDialog(AppLocalizations l10n) async {
    final reasonController = TextEditingController();
    String? dialogError;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: KickPulseColors.surfaceElevated,
              title: Text(
                l10n.tournamentAuditDialogTitle,
                style: KickPulseTypography.cardTitle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tournamentAuditDialogMessage,
                    style: KickPulseTypography.bodyPrimary,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  TextField(
                    key: const Key('audit_reason_input'),
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: l10n.tournamentAuditReasonLabel,
                      hintText: l10n.tournamentAuditReasonHint,
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.actionCancel),
                ),
                ElevatedButton(
                  key: const Key('confirm_audit_override_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KickPulseColors.accentPrimary,
                    foregroundColor: KickPulseColors.canvasBackground,
                  ),
                  onPressed: () {
                    final text = reasonController.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        dialogError = l10n.tournamentErrorAuditReasonRequired;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(text);
                  },
                  child: Text(l10n.tournamentAuditConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleBackAttempt() async {
    if (!_isDirty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final l10n = AppLocalizations.of(context);
    final decision = await showDialog<_ExitDecision>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: KickPulseColors.surfaceElevated,
          title: Text(
            l10n.tournamentExitDialogTitle,
            style: KickPulseTypography.cardTitle,
          ),
          content: Text(
            l10n.tournamentExitDialogMessage,
            style: KickPulseTypography.bodyPrimary,
          ),
          actions: [
            TextButton(
              key: const Key('continue_editing_tournament_button'),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_ExitDecision.continueEditing),
              child: Text(l10n.tournamentContinueEditingAction),
            ),
            if (!_isEditMode)
              OutlinedButton(
                key: const Key('save_tournament_draft_button'),
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_ExitDecision.saveDraft),
                child: Text(l10n.tournamentSaveDraftAction),
              ),
            TextButton(
              key: const Key('discard_tournament_changes_button'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitDecision.discardChanges),
              child: Text(
                l10n.tournamentDiscardChangesAction,
                style: const TextStyle(color: KickPulseColors.accentLive),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        decision == null ||
        decision == _ExitDecision.continueEditing) {
      return;
    }

    if (decision == _ExitDecision.saveDraft) {
      await _persistLocalDraft();
    } else if (decision == _ExitDecision.discardChanges && !_isEditMode) {
      await ref.read(tournamentsControllerProvider.notifier).clearDraft();
    }

    if (!mounted) return;
    setState(() {
      _isDirty = false;
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _moveTiebreaker(int index, int delta) {
    final targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= _tiebreakerOrder.length) return;
    setState(() {
      final item = _tiebreakerOrder.removeAt(index);
      _tiebreakerOrder.insert(targetIndex, item);
      _isDirty = true;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _isDirty = true;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = widget.initialTournament;
    final isInProgress = existing?.status == TournamentStatus.inProgress;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          leading: IconButton(
            key: const Key('tournament_form_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackAttempt,
          ),
          title: Text(
            _isEditMode
                ? l10n.tournamentFormEditTitle
                : l10n.tournamentFormCreateTitle,
            style: KickPulseTypography.cardTitle,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_restoredFromDraft) ...[
                  Container(
                    key: const Key('restored_draft_banner'),
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.accentElectric.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      border: Border.all(color: KickPulseColors.accentElectric),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restore_page_outlined,
                          color: KickPulseColors.accentElectric,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            l10n.tournamentsDraftBannerTitle,
                            style: KickPulseTypography.bodyPrimary,
                          ),
                        ),
                        TextButton(
                          key: const Key('clear_restored_draft_button'),
                          onPressed: () async {
                            await ref
                                .read(tournamentsControllerProvider.notifier)
                                .clearDraft();
                            if (!mounted) return;
                            setState(() {
                              _restoredFromDraft = false;
                              _nameController.clear();
                              _isDirty = false;
                            });
                          },
                          child: Text(l10n.tournamentsDraftBannerClear),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ],
                if (isInProgress) ...[
                  Container(
                    key: const Key('critical_rule_lock_banner'),
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.accentWarning.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      border: Border.all(color: KickPulseColors.accentWarning),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: KickPulseColors.accentWarning,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            l10n.tournamentCriticalRuleLockBanner,
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ],
                if (_validationErrorMessage != null) ...[
                  Container(
                    key: const Key('tournament_validation_error_banner'),
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.accentLive.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      border: Border.all(color: KickPulseColors.accentLive),
                    ),
                    child: Text(
                      _validationErrorMessage!,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.accentLive,
                      ),
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ],
                KickPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const Key('tournament_name_input'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.tournamentFormNameLabel,
                          hintText: l10n.tournamentFormNameHint,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextField(
                        key: const Key('tournament_category_input'),
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: l10n.tournamentFormCategoryLabel,
                          hintText: l10n.tournamentFormCategoryHint,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('tournament_start_date_button'),
                              onPressed: () => _pickDate(isStart: true),
                              icon: const Icon(Icons.event, size: 18),
                              label: Text(
                                '${l10n.tournamentFormStartDateLabel}: ${_formatDate(_startDate)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('tournament_end_date_button'),
                              onPressed: () => _pickDate(isStart: false),
                              icon: const Icon(Icons.event_available, size: 18),
                              label: Text(
                                '${l10n.tournamentFormEndDateLabel}: ${_formatDate(_endDate)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      Text(
                        l10n.tournamentFormFormatLabel,
                        style: KickPulseTypography.sectionHeader,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      Wrap(
                        spacing: KickPulseRadiiSpacing.spaceSm,
                        runSpacing: KickPulseRadiiSpacing.spaceXs,
                        children: TournamentFormat.values.map((format) {
                          final selected = _format == format;
                          return ChoiceChip(
                            key: Key('format_chip_${format.name}'),
                            label: Text(l10n.formatLabel(format)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _format = format;
                                _isDirty = true;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KickPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tournamentScoringTitle,
                        style: KickPulseTypography.cardTitle,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('points_win_input'),
                              controller: _winPointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tournamentPointsWin,
                              ),
                            ),
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: TextField(
                              key: const Key('points_draw_input'),
                              controller: _drawPointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tournamentPointsDraw,
                              ),
                            ),
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: TextField(
                              key: const Key('points_loss_input'),
                              controller: _lossPointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tournamentPointsLoss,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_format.hasStandingsTable) ...[
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        Text(
                          l10n.tournamentTiebreakersTitle,
                          style: KickPulseTypography.sectionHeader,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                        ...List<Widget>.generate(_tiebreakerOrder.length, (
                          index,
                        ) {
                          final criterion = _tiebreakerOrder[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      KickPulseColors.surfaceSubtle,
                                  child: Text(
                                    '${index + 1}',
                                    style: KickPulseTypography.microBadge,
                                  ),
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.tiebreakerLabel(criterion),
                                    style: KickPulseTypography.bodyPrimary,
                                  ),
                                ),
                                IconButton(
                                  key: Key('tiebreaker_up_${criterion.name}'),
                                  icon: const Icon(
                                    Icons.arrow_upward,
                                    size: 18,
                                  ),
                                  onPressed: index > 0
                                      ? () => _moveTiebreaker(index, -1)
                                      : null,
                                ),
                                IconButton(
                                  key: Key('tiebreaker_down_${criterion.name}'),
                                  icon: const Icon(
                                    Icons.arrow_downward,
                                    size: 18,
                                  ),
                                  onPressed: index < _tiebreakerOrder.length - 1
                                      ? () => _moveTiebreaker(index, 1)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                if (_format == TournamentFormat.league)
                  KickPulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tournamentLeagueRoundsLabel,
                          style: KickPulseTypography.cardTitle,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Wrap(
                          spacing: KickPulseRadiiSpacing.spaceSm,
                          children: [
                            ChoiceChip(
                              key: const Key('league_rounds_1_chip'),
                              label: Text(l10n.tournamentLeagueSingleRound),
                              selected: _leagueRounds == 1,
                              onSelected: (_) {
                                setState(() {
                                  _leagueRounds = 1;
                                  _isDirty = true;
                                });
                              },
                            ),
                            ChoiceChip(
                              key: const Key('league_rounds_2_chip'),
                              label: Text(l10n.tournamentLeagueDoubleRound),
                              selected: _leagueRounds == 2,
                              onSelected: (_) {
                                setState(() {
                                  _leagueRounds = 2;
                                  _isDirty = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (_format.hasGroupStage) ...[
                  KickPulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tournamentGroupStageTitle,
                          style: KickPulseTypography.cardTitle,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('group_count_input'),
                                controller: _groupCountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.tournamentGroupCountLabel,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: TextField(
                                key: const Key('advancing_per_group_input'),
                                controller: _advancingPerGroupController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.tournamentAdvancingPerGroupLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ],
                if (_format.hasKnockoutBracket) ...[
                  KickPulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tournamentKnockoutStructureTitle,
                          style: KickPulseTypography.cardTitle,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Text(
                          l10n.tournamentStartingRoundLabel,
                          style: KickPulseTypography.sectionHeader,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                        Wrap(
                          spacing: KickPulseRadiiSpacing.spaceSm,
                          children: KnockoutRound.values.map((round) {
                            return ChoiceChip(
                              key: Key('starting_round_chip_${round.name}'),
                              label: Text(l10n.knockoutRoundLabel(round)),
                              selected: _startingRound == round,
                              onSelected: (_) {
                                setState(() {
                                  _startingRound = round;
                                  _isDirty = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.tournamentDirectPenaltiesLabel,
                                style: KickPulseTypography.bodyPrimary,
                              ),
                            ),
                            Switch(
                              key: const Key('direct_penalties_switch'),
                              value: _directPenaltyShootout,
                              onChanged: (value) {
                                setState(() {
                                  _directPenaltyShootout = value;
                                  _isDirty = true;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.tournamentTwoLeggedTiesLabel,
                                style: KickPulseTypography.bodyPrimary,
                              ),
                            ),
                            Switch(
                              key: const Key('two_legged_ties_switch'),
                              value: _twoLeggedTies,
                              onChanged: (value) {
                                setState(() {
                                  _twoLeggedTies = value;
                                  _isDirty = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ],
                KickPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tournamentDisciplinaryAndSquadTitle,
                        style: KickPulseTypography.cardTitle,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      TextField(
                        key: const Key('yellow_cards_limit_input'),
                        controller: _yellowCardsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.tournamentYellowCardLimitLabel,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('min_players_input'),
                              controller: _minPlayersController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tournamentMinPlayersLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: TextField(
                              key: const Key('max_players_input'),
                              controller: _maxPlayersController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tournamentMaxPlayersLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      TextField(
                        key: const Key('half_duration_input'),
                        controller: _halfDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.tournamentHalfDurationLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KickPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.venuesSectionTitle,
                                  style: KickPulseTypography.cardTitle,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.venuesSectionSubtitle,
                                  style: KickPulseTypography.captionMeta,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('create_new_venue_inline_button'),
                            onPressed: _handleCreateNewVenue,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.createNewVenue),
                          ),
                        ],
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Consumer(
                        builder: (context, ref, _) {
                          List<SportsVenue> venues = const [];
                          try {
                            venues = ref.watch(venuesControllerProvider).venues;
                          } catch (_) {
                            // Defensive for isolated test environments
                          }
                          if (venues.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n.noVenuesRegistered,
                                style: KickPulseTypography.captionMeta,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: venues.map((venue) {
                              final isSelected = _selectedVenueIds.contains(
                                venue.id,
                              );
                              return FilterChip(
                                key: Key('venue_chip_${venue.id}'),
                                label: Text(venue.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedVenueIds.add(venue.id);
                                    } else {
                                      _selectedVenueIds.remove(venue.id);
                                    }
                                    _isDirty = true;
                                  });
                                },
                                selectedColor: KickPulseColors.accentPrimary
                                    .withValues(alpha: 0.2),
                                checkmarkColor: KickPulseColors.accentPrimary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? KickPulseColors.accentPrimary
                                      : KickPulseColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                KickPulseButton(
                  key: const Key('save_tournament_submit_button'),
                  label: _isEditMode
                      ? l10n.tournamentFormSaveEditAction
                      : l10n.tournamentFormSaveCreateAction,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ExitDecision { saveDraft, discardChanges, continueEditing }
